defmodule BattleCity.Context do
  @moduledoc """
  Context
  """

  alias BattleCity.Bullet
  alias BattleCity.Config
  alias BattleCity.ContextCallback
  alias BattleCity.Core.Generate
  alias BattleCity.Environment
  alias BattleCity.Event
  alias BattleCity.Position
  alias BattleCity.PowerUp
  alias BattleCity.Stage
  alias BattleCity.Tank

  require Logger

  @type callback_fn :: (t() -> t())
  @typep state :: :started | :paused | :game_over | :complete
  @typep grid_struct :: PowerUp.t() | Tank.t() | Bullet.t() | Environment.t()
  @type object_struct :: PowerUp.t() | Tank.t() | Bullet.t() | nil
  @type update_raw_fun :: (object_struct -> {object_struct, object_struct})

  @typep grid :: %{
           required(:type) => BattleCity.short_type(),
           required(:x) => integer(),
           required(:y) => integer(),
           optional(:h) => boolean(),
           optional(:d) => atom() | binary(),
           optional(:kind) => atom()
         }

  @object_struct_map %{PowerUp => :power_ups, Tank => :tanks, Bullet => :bullets}
  @object_values Map.values(@object_struct_map)

  @type t :: %__MODULE__{
          rest_enemies: integer(),
          rest_players: integer(),
          shovel?: boolean(),
          mock: boolean(),
          level: BattleCity.level(),
          loop_interval: integer(),
          bot_loop_interval: integer(),
          timeout_interval: integer(),
          enable_bot: boolean(),
          __counters__: map(),
          __events__: [Event.t()],
          __opts__: map(),
          __global_callbacks__: [callback_fn],
          state: state(),
          score: integer(),
          objects: %{Position.coordinate() => %{Object.t() => Object.value()}},
          stage: Stage.t(),
          power_ups: %{BattleCity.id() => PowerUp.t()},
          tanks: %{BattleCity.id() => Tank.t()},
          bullets: %{BattleCity.id() => Bullet.t()}
        }

  @enforce_keys [
    :stage,
    :level,
    :slug,
    :timeout_interval,
    :loop_interval,
    :bot_loop_interval,
    :enable_bot,
    :mock,
    :score,
    :__opts__
  ]
  @derive {SimpleDisplay,
           only: [:level, :rest_enemies, :shovel?, :state, :loop_interval, :timeout_interval]}
  defstruct @enforce_keys ++
              [
                rest_players: 1,
                tanks: %{},
                bullets: %{},
                power_ups: %{},
                objects: %{},
                __events__: [],
                __global_callbacks__: [],
                __counters__: %{player: 0, power_up: 0, bullet: 0, enemy: 0, event: 0, loop: 0},
                rest_enemies: Config.get(:rest_enemies),
                state: :started,
                shovel?: false
              ]

  @spec grid(grid_struct) :: grid
  def grid(%Environment{position: p, shape: shape, __module__: module}) do
    %{type: :e, kind: module.__name__(), x: p.rx, y: p.ry, d: shape}
  end

  def grid(%Tank{position: p, __module__: module, hidden?: hidden?}) do
    %{type: :t, kind: module.__name__(), x: p.rx, y: p.ry, d: p.direction, h: hidden?}
  end

  def grid(%Bullet{position: p, hidden?: hidden?}) do
    %{type: :b, x: p.rx, y: p.ry, d: p.direction, h: hidden?}
  end

  def grid(%PowerUp{position: p, __module__: module, hidden?: hidden?}) do
    %{type: :p, x: p.rx, y: p.ry, kind: module.__name__(), h: hidden?}
  end

  @spec grids(t()) :: [grid]
  def grids(%__MODULE__{} = ctx) do
    map_grids(ctx) ++ object_grids(ctx)
  end

  @spec map_grids(t()) :: [grid]
  def map_grids(%__MODULE__{stage: %{map: map}}) do
    for {_k, o} <- map, do: grid(o)
  end

  def non_empty_objects(%__MODULE__{objects: objects}) do
    for {xy, mapset} <- objects, map_size(mapset) > 0, reduce: [] do
      ary ->
        o = for {%{type: t, id: id}, _} <- mapset, do: {xy, t, id}
        ary ++ o
    end
  end

  @spec tank_grids(t()) :: [grid]
  def tank_grids(ctx), do: object_grids(ctx, [:t])
  @spec bullet_grids(t()) :: [grid]
  def bullet_grids(ctx), do: object_grids(ctx, [:b])
  @spec power_up_grids(t()) :: [grid]
  def power_up_grids(ctx), do: object_grids(ctx, [:p])

  @spec object_grids(t(), nil | [BattleCity.short_type()]) :: [grid]
  def object_grids(%__MODULE__{objects: objects} = ctx, types \\ nil) do
    types = types || [:b, :t, :p]

    for {_, mapset} <- objects, map_size(mapset) > 0, reduce: [] do
      ary ->
        o =
          for {%{type: t, id: id}, _} <- mapset,
              t in types,
              do: fetch_object!(ctx, t, id) |> grid()

        ary ++ o
    end
  end

  @spec camp?(Object.kv(), boolean()) :: boolean()
  def camp?({%{type: :t, enemy?: b}, _}, b), do: true
  def camp?({%{type: :b, enemy?: b}, _}, b), do: true
  def camp?(_, _), do: false

  @spec camp_direction?({Object.kv(), Position.direction()}, boolean()) :: boolean()
  def camp_direction?(_, _), do: false

  @spec path_object(t(), Position.t(), Position.direction() | nil) :: [Object.kv()]
  def path_object(%__MODULE__{objects: objects}, position, direction \\ nil) do
    for xy <- Position.target_path(position, direction || position.direction), reduce: [] do
      ary -> ary ++ for kv <- Map.fetch!(objects, xy), do: kv
    end
  end

  @spec all_path_object(t(), Position.t()) :: [{Object.kv(), Position.direction()}]
  def all_path_object(ctx, position) do
    for direction <- [:up, :down, :left, :right], reduce: [] do
      ary -> ary ++ for i <- path_object(ctx, position, direction), do: {i, direction}
    end
  end

  @spec bot_loop(t()) :: boolean()
  def bot_loop(%__MODULE__{state: :started, enable_bot: true}), do: true
  def bot_loop(_), do: false

  @spec initial_objects(t()) :: t()
  def initial_objects(%__MODULE__{} = ctx) do
    %{ctx | objects: Position.objects()}
  end

  @spec put_object({t(), object_struct}) :: t()
  def put_object({ctx, obj}), do: put_object(ctx, obj)

  @spec put_object(t(), object_struct | [object_struct]) :: t()
  def put_object(ctx, nil), do: ctx
  def put_object(ctx, []), do: ctx
  def put_object(ctx, [o | rest]), do: ctx |> put_object(o) |> put_object(rest)

  def put_object(%{__counters__: %{bullet: i} = c} = ctx, %Bullet{id: nil} = o) do
    i = i + 1
    put_object(%{ctx | __counters__: %{c | bullet: i}}, %{o | id: "b#{i}"})
  end

  def put_object(%{__counters__: %{power_up: i} = c} = ctx, %PowerUp{id: nil} = o) do
    i = i + 1
    put_object(%{ctx | __counters__: %{c | power_up: i}}, %{o | id: "p#{i}"})
  end

  def put_object(%{__counters__: %{enemy: i} = c} = ctx, %Tank{id: nil, enemy?: true} = o) do
    i = i + 1
    put_object(%{ctx | __counters__: %{c | enemy: i}}, Tank.normalize(o, i))
  end

  def put_object(%{__counters__: %{player: i} = c} = ctx, %Tank{id: nil, enemy?: false} = o) do
    i = i + 1
    put_object(%{ctx | __counters__: %{c | player: i}}, Tank.normalize(o, i))
  end

  def put_object(ctx, o) do
    ctx |> handle_actions(o, o.__callbacks__) |> handle_object(%{o | __callbacks__: []})
  end

  @spec handle_actions(t(), object_struct, [ContextCallback.t()]) :: t()
  def handle_actions(ctx, _, []), do: ctx

  def handle_actions(ctx, o, [a | rest]) do
    ctx = ContextCallback.handle(a, o, ctx)
    handle_actions(ctx, o, rest)
  end

  @spec handle_object(t(), object_struct) :: t()
  def handle_object(ctx, %Tank{dead?: true, id: id}), do: delete_object(ctx, :tanks, id)
  def handle_object(ctx, %Bullet{dead?: true, id: id}), do: delete_object(ctx, :bullets, id)
  def handle_object(ctx, %Tank{changed?: false}), do: ctx

  def handle_object(ctx, %Tank{changed?: true} = tank),
    do: put_changed_object(ctx, %{tank | changed?: false})

  def handle_object(ctx, other), do: put_changed_object(ctx, other)

  @spec put_changed_object(t(), object_struct) :: t()
  def put_changed_object(
        %__MODULE__{} = ctx,
        %{
          position: %{} = position,
          id: id,
          __struct__: struct
        } = o
      ) do
    key = Map.fetch!(@object_struct_map, struct)
    old = ctx |> Map.fetch!(key) |> Map.get(id)

    %{x: x, y: y} = Position.normalize(position)

    {{old_x, old_y}, action} =
      if old, do: {{old.position.x, old.position.y}, :update}, else: {{x, y}, :create}

    %{objects: objects} = ctx = ContextCallback.handle(%ContextCallback{action: action}, o, ctx)
    # IO.puts("#{action} #{ctx.slug} #{key} #{id} {#{x}, #{y}}")

    {fingerprint, fingerprint_value} = Object.fingerprint(o)
    new_o = objects |> Map.fetch!({x, y}) |> Map.put(fingerprint, fingerprint_value)

    diff =
      if {old_x, old_y} == {x, y} do
        %{{x, y} => new_o}
      else
        %{x: old_x, y: old_y} = old.position
        old_o = objects |> Map.fetch!({old_x, old_y}) |> Map.delete(fingerprint)
        %{{x, y} => new_o, {old_x, old_y} => old_o}
      end

    Map.merge(ctx, %{
      key => ctx |> Map.fetch!(key) |> Map.put(id, o),
      :objects => Map.merge(objects, diff)
    })
  end

  def fetch_object(ctx, :t, id), do: fetch_object(ctx, :tanks, id)
  def fetch_object(ctx, :p, id), do: fetch_object(ctx, :power_ups, id)
  def fetch_object(ctx, :b, id), do: fetch_object(ctx, :bullets, id)
  def fetch_object(ctx, key, id), do: ctx |> Map.fetch!(key) |> Map.get(id)

  def fetch_object!(ctx, key, id) do
    fetch_object(ctx, key, id) || raise("Can't find: #{key}, #{id}")
  end

  @spec update_object_raw(t(), BattleCity.object_keys(), BattleCity.id(), update_raw_fun) :: t()
  def update_object_raw(ctx, key, id, f) do
    ctx
    |> Map.fetch!(key)
    |> Map.get_and_update(id, f)
    |> case do
      {nil, _} -> ctx
      {_, data} -> Map.put(ctx, key, data)
    end
  end

  @spec update_object_and_ctx!(
          t(),
          BattleCity.object_keys(),
          BattleCity.id(),
          (... -> {term(), t(), object_struct}),
          [term()]
        ) :: {term(), t(), object_struct()}
  def update_object_and_ctx!(ctx, key, id, f, extra \\ []) do
    data = ctx |> Map.fetch!(key)

    {{result, ctx, o}, data} =
      Map.get_and_update!(data, id, fn o ->
        {result, ctx, o} = apply(f, [ctx, o | extra])
        {{result, ctx, o}, o}
      end)

    {result, Map.put(ctx, key, data), o}
  end

  @spec update_object_raw!(t(), BattleCity.object_keys(), BattleCity.id(), update_raw_fun) :: t()
  def update_object_raw!(ctx, key, id, f) do
    {_, data} = ctx |> Map.fetch!(key) |> Map.get_and_update!(id, f)
    Map.put(ctx, key, data)
  end

  @spec delete_object(t(), BattleCity.object_keys(), BattleCity.id()) :: t()
  def delete_object(ctx, key, id) when key in @object_values do
    %{objects: objects} =
      ctx =
      ContextCallback.handle(
        %ContextCallback{action: :delete},
        ctx |> Map.fetch!(key) |> Map.fetch!(id),
        ctx
      )

    data = ctx |> Map.fetch!(key)
    {o, data} = Map.pop!(data, id)
    xy = {o.position.x, o.position.y}
    # IO.puts("[delete] #{ctx.slug} #{key} #{id}")
    o = Map.delete(objects |> Map.fetch!(xy), Object.fingerprint(o) |> elem(0))

    ctx |> Map.merge(%{key => data, :objects => Map.put(objects, xy, o)})
  end

  @spec handle_callbacks(t()) :: t()
  def handle_callbacks(%{__global_callbacks__: []} = ctx), do: ctx

  def handle_callbacks(%{__global_callbacks__: [f | rest]} = ctx) do
    ctx = f.(ctx)
    handle_callbacks(%{ctx | __global_callbacks__: rest})
  end

  @spec maybe_add_points(t(), Tank.t()) :: t()
  def maybe_add_points(%__MODULE__{score: score} = ctx, %Tank{
        enemy?: true,
        dead?: true,
        reason: :hit,
        meta: %{points: points}
      }) do
    %{ctx | score: score + points}
  end

  def maybe_add_points(ctx, _), do: ctx

  @spec maybe_add_power_up(t(), Tank.t()) :: t()
  def maybe_add_power_up(ctx, %Tank{with_power_up?: false}), do: ctx
  def maybe_add_power_up(ctx, _), do: Generate.add_power_up(ctx)
end

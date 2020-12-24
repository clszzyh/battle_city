defmodule BattleCity.Ai do
  @moduledoc false

  alias BattleCity.Context
  alias BattleCity.Event
  alias BattleCity.Tank

  @type t :: %__MODULE__{
          __module__: module(),
          slug: BattleCity.slug(),
          id: BattleCity.id(),
          interval: integer,
          loop: boolean(),
          pid: pid(),
          private: term(),
          move_event: maybe_event,
          shoot_event: maybe_event
        }

  @enforce_keys [:slug, :id, :interval, :loop, :__module__]
  defstruct @enforce_keys ++ [:pid, :move_event, :shoot_event, :private]

  @typep maybe_tank :: Tank.t() | nil
  @typep maybe_event :: Event.t() | nil
  @typep callback_atom :: nil | :same | :ok
  @typep event_key :: :move_event | :shoot_event
  @typep callback_result :: {callback_atom, t()} | maybe_event
  @typep handle_result :: {maybe_event, t()}

  @callback name :: binary()
  @callback handle_move(t(), Context.t(), Tank.t()) :: callback_result
  @callback handle_shoot(t(), Context.t(), Tank.t()) :: callback_result

  @behaviour Access
  @impl true
  def fetch(struct, key), do: Map.fetch(struct, key)
  @impl true
  def get_and_update(struct, key, fun) when is_function(fun, 1),
    do: Map.get_and_update(struct, key, fun)

  @impl true
  def pop(struct, key), do: Map.pop(struct, key)

  defmacro __using__(_opts) do
    quote location: :keep do
      alias BattleCity.Context
      alias BattleCity.Event
      alias BattleCity.Position
      alias BattleCity.Tank

      import BattleCity.Position, only: [is_on_border_xy: 1]

      alias unquote(__MODULE__)

      @diretions [:up, :down, :left, :right]

      @behaviour unquote(__MODULE__)
    end
  end

  @spec has_enemies?(Context.t(), Tank.t()) :: boolean()
  def has_enemies?(ctx, %Tank{position: position, enemy?: enemy?}) do
    ctx
    |> Context.path_object(position)
    |> Enum.any?(&Context.camp?(&1, !enemy?))
  end

  def sighted?(ctx, %Tank{position: position, enemy?: enemy?}) do
    ctx
    |> Context.all_path_object(position)
    |> Enum.any?(&Context.camp_direction?(&1, !enemy?))
  end

  @spec move(t(), Context.t(), maybe_tank) :: handle_result
  def move(ai, _, nil), do: {nil, ai}
  def move(ai, _, %Tank{dead?: true}), do: {nil, ai}
  def move(ai, _, %Tank{freezed?: true}), do: {nil, ai}

  def move(%{__module__: module} = ai, ctx, tank) do
    module.handle_move(ai, ctx, tank) |> handle_result(ai, ctx, tank, :move_event)
  end

  @spec shoot(t(), Context.t(), maybe_tank) :: handle_result
  def shoot(ai, _, nil), do: {nil, ai}
  def shoot(ai, _, %Tank{dead?: true}), do: {nil, ai}
  def shoot(ai, _, %Tank{shootable?: false}), do: {nil, ai}

  def shoot(%{__module__: module} = ai, ctx, tank) do
    module.handle_shoot(ai, ctx, tank) |> handle_result(ai, ctx, tank, :shoot_event)
  end

  @spec handle_result(callback_result(), t(), Context.t(), Tank.t(), event_key) :: handle_result
  defp handle_result(nil, ai, _, _, _), do: {nil, ai}
  defp handle_result({nil, %__MODULE__{} = ai}, _, _, _, _), do: {nil, ai}
  defp handle_result({:same, %__MODULE__{} = ai}, _, _, _, key), do: {ai[key], ai}

  defp handle_result({:ok, %__MODULE__{} = ai}, _, ctx, tank, key) do
    handle_result(ai[key], ai, ctx, tank, key)
  end

  defp handle_result(%Event{} = event, ai, ctx, tank, key) do
    event = %{event | id: tank.id, counter: ctx.__counters__.loop}
    {event, %{ai | key => event}}
  end
end

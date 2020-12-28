defmodule BattleCity.PowerUp do
  @moduledoc """
  PowerUp
  """

  alias BattleCity.Config
  alias BattleCity.Context
  alias BattleCity.ContextCallback
  alias BattleCity.Position
  alias BattleCity.Process.GameServer
  alias BattleCity.Tank

  @typep duration :: integer() | :instant

  @type t :: %__MODULE__{
          __module__: module(),
          id: BattleCity.id(),
          duration: duration(),
          position: Position.t(),
          hidden?: boolean(),
          tank_id: BattleCity.id() | nil,
          __ref__: reference(),
          __callbacks__: [ContextCallback.t()]
        }

  @enforce_keys []
  defstruct [
    :__module__,
    :id,
    :position,
    :__ref__,
    :tank_id,
    hidden?: false,
    __callbacks__: [],
    duration: Config.get(:power_up_duration)
  ]

  use BattleCity.StructCollect

  @typep power_up_result :: {Context.t(), Tank.t()}
  @typep maybe_power_up_f :: nil | Context.update_raw_fun()

  @callback handle_add(Context.t(), Tank.t()) :: power_up_result
  @callback handle_remove(Context.t(), Tank.t()) :: power_up_result
  @optional_callbacks handle_remove: 2

  defmacro __using__(opt \\ []) do
    obj = struct(__MODULE__, opt)

    quote location: :keep do
      alias BattleCity.Context
      alias BattleCity.Core
      alias BattleCity.Tank

      init_ast(unquote(__MODULE__), __MODULE__, unquote(Macro.escape(obj)), unquote(opt))

      @impl true
      def handle_init(%{} = map) do
        Map.put(
          map,
          :position,
          Position.init(
            map
            |> Map.merge(%{__parent__: unquote(__MODULE__), __module__: __MODULE__})
          )
        )
      end
    end
  end

  use BattleCity.ContextCallback

  @impl true
  def handle_callback(%{action: :create}, %__MODULE__{id: me}, %{power_ups: power_ups} = ctx) do
    for {id, _} <- power_ups, id != me, reduce: ctx do
      ctx -> Context.delete_object(ctx, :power_ups, id)
    end
  end

  def handle_callback(_, _, ctx), do: ctx

  @spec add(Context.t(), Tank.t(), t()) :: {Context.t(), Tank.t(), maybe_power_up_f}
  def add(%{slug: slug} = ctx, %Tank{} = tank, %__MODULE__{
        __module__: module,
        id: id,
        duration: duration
      }) do
    {ctx, tank} = module.handle_add(ctx, tank)

    if is_integer(duration) do
      srv = GameServer.pid(slug)

      if srv do
        ref = Process.send_after(srv, {:remove_power_up, id}, duration)

        {ctx, tank,
         fn p -> {p, Map.merge(p, %{__ref__: ref, tank_id: tank.id, hidden?: true})} end}
      else
        {ctx, tank, nil}
      end
    else
      {ctx, tank, nil}
    end
  end

  @spec remove(Context.t(), Tank.t(), t()) :: power_up_result
  def remove(ctx, %Tank{} = tank, %__MODULE__{__module__: module}) do
    module.handle_remove(ctx, tank)
  end
end

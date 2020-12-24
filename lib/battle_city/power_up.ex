defmodule BattleCity.PowerUp do
  @moduledoc """
  PowerUp
  """

  alias BattleCity.Callback
  alias BattleCity.Config
  alias BattleCity.Context
  alias BattleCity.Position
  alias BattleCity.Tank

  @typep duration :: integer() | :instant

  @type t :: %__MODULE__{
          __module__: module(),
          id: BattleCity.id(),
          duration: duration(),
          position: Position.t(),
          __callbacks__: [Callback.t()]
        }

  @enforce_keys []
  defstruct [
    :__module__,
    :id,
    :position,
    __callbacks__: [],
    duration: Config.get(:power_up_duration)
  ]

  use BattleCity.StructCollect

  @callback handle_on(Context.t(), Tank.t()) :: BattleCity.invoke_tank_result()
  @callback handle_off(Context.t(), Tank.t()) :: BattleCity.invoke_tank_result()
  @optional_callbacks handle_off: 2

  defmacro __using__(opt \\ []) do
    obj = struct(__MODULE__, opt)

    quote location: :keep do
      alias BattleCity.Business
      alias BattleCity.Context
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

  use BattleCity.Callback

  @impl true
  def handle_callback(_, _, ctx), do: ctx

  @spec add(Tank.t(), t()) :: Tank.t()
  def add(%Tank{} = tank, %__MODULE__{}) do
    tank
  end

  # @spec on(Context.t(), Tank.t(), t()) :: BattleCity.invoke_result()
  # def on(%Context{} = ctx, %Tank{} = tank, %__MODULE__{} = powerup) do
  #   powerup.__module__.handle_on(ctx, tank)
  #   |> BattleCity.parse_tank_result(ctx, tank)
  #   |> Context.put_object()
  # end

  # @spec off(Context.t(), Tank.t(), t()) :: BattleCity.invoke_result()
  # def off(%Context{} = ctx, %Tank{} = tank, %__MODULE__{} = powerup) do
  #   if function_exported?(powerup.__module__, :handle_off, 2) do
  #     powerup.__module__.handle_off(ctx, tank)
  #     |> BattleCity.parse_tank_result(ctx, tank)
  #     |> Context.put_object()
  #   else
  #     Context.put_object(ctx, tank)
  #   end
  # end
end

defmodule BattleCity.Environment do
  @moduledoc """
  Environment
  """

  alias BattleCity.Bullet
  alias BattleCity.Callback
  alias BattleCity.Position
  alias BattleCity.Tank

  @typep health :: integer() | :infinite
  @typep shape :: nil | binary()
  @type object :: Tank.t() | Bullet.t()
  @typep enter_result :: {:error, BattleCity.reason()} | {:ok, object}

  @type t :: %__MODULE__{
          __module__: module(),
          id: BattleCity.id(),
          enter?: boolean(),
          health: health,
          shape: shape,
          raw: binary(),
          position: Position.t()
        }

  @enforce_keys [:enter?, :health]
  defstruct [
    :__module__,
    :id,
    :shape,
    :raw,
    :position,
    enter?: false,
    health: 0
  ]

  use BattleCity.StructCollect

  @callback handle_enter(t(), object) :: enter_result
  @callback handle_leave(t(), object) :: enter_result

  defmacro __using__(opt \\ []) do
    obj = struct(__MODULE__, opt)

    quote location: :keep do
      alias BattleCity.Tank
      @impl true
      def handle_enter(_, o), do: {:ok, o}
      @impl true
      def handle_leave(_, o), do: {:ok, o}
      init_ast(unquote(__MODULE__), __MODULE__, unquote(Macro.escape(obj)), unquote(opt))
    end
  end

  @spec copy_rxy(t(), object) :: object
  def copy_rxy(%{position: %{rx: rx, ry: ry}}, %{position: position} = o) do
    %{o | position: %{position | rx: rx, ry: ry, path: []}}
  end

  @spec copy_xy(t(), object) :: object
  def copy_xy(
        %{position: %{x: x, y: y}},
        %{position: %{path: [_ | rest]} = position} = o
      ) do
    %{o | position: %{position | x: x, y: y, path: rest}}
  end

  @spec enter(t(), object) :: enter_result
  def enter(%__MODULE__{enter?: false}, %Tank{}), do: {:error, :forbidden}

  def enter(%__MODULE__{enter?: false, health: :infinite}, %Bullet{} = bullet),
    do: {:ok, %{bullet | dead?: true}}

  def enter(
        %__MODULE__{enter?: false, health: health, position: p},
        %Bullet{__callbacks__: callbacks} = bullet
      )
      when health > 0 do
    callback = %Callback{
      action: :damage_environment,
      value: %{x: p.x, y: p.y, power: bullet.power}
    }

    {:ok, %{bullet | dead?: true, __callbacks__: [callback | callbacks]}}
  end

  def enter(%__MODULE__{__module__: module} = environment, o) do
    module.handle_enter(environment, o)
  end

  @spec leave(t(), object) :: enter_result
  def leave(%__MODULE__{__module__: module} = environment, o) do
    module.handle_leave(environment, o)
  end

  @spec hit(t(), integer) :: t()
  def hit(%__MODULE__{health: health} = env, damage) when health > 0 and health > damage do
    %{env | health: health - damage}
  end

  def hit(%__MODULE__{health: health} = env, _) when health > 0 do
    reset(env, BattleCity.Environment.Blank)
  end

  def hit(%__MODULE__{} = e, _), do: e

  @spec reset(t(), module()) :: t()
  def reset(%__MODULE__{} = env, module) do
    %{health: health, enter?: enter?} = module.init

    %{
      env
      | __module__: module,
        health: health,
        enter?: enter?
    }
  end
end

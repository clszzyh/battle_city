defmodule BattleCity.Environment do
  @moduledoc """
  Environment
  """

  alias BattleCity.Bullet
  alias BattleCity.ContextCallback
  alias BattleCity.Position
  alias BattleCity.Tank

  @typep health :: integer() | :infinite
  @typep shape :: :full | :top | :bottom | :left | :right | :left_bottom | :right_bottom | :dead
  @type env_object :: Tank.t() | Bullet.t()
  @typep enter_result :: {:error, BattleCity.reason()} | {:ok, env_object}

  @type t :: %__MODULE__{
          __module__: module(),
          id: BattleCity.id(),
          enter?: boolean(),
          health: health,
          shape: shape,
          raw: binary(),
          solid?: boolean(),
          position: Position.t()
        }

  @enforce_keys [:enter?, :health]
  defstruct [
    :__module__,
    :id,
    :shape,
    :raw,
    :position,
    solid?: false,
    enter?: false,
    health: 0
  ]

  use BattleCity.StructCollect

  @callback handle_enter(t(), env_object) :: enter_result
  @callback handle_leave(t(), env_object) :: enter_result

  defmacro __using__(opt \\ []) do
    obj = struct(__MODULE__, opt)

    quote location: :keep do
      alias BattleCity.Environment
      alias BattleCity.Tank
      @impl true
      def handle_enter(_, o), do: {:ok, o}
      @impl true
      def handle_leave(_, o), do: {:ok, o}
      init_ast(unquote(__MODULE__), __MODULE__, unquote(Macro.escape(obj)), unquote(opt))
    end
  end

  @spec copy_rxy(t(), env_object) :: env_object
  def copy_rxy(%{position: %{rx: rx, ry: ry}}, %{position: position} = o) do
    %{o | position: %{position | rx: rx, ry: ry, path: []}}
  end

  @spec copy_xy(t(), env_object) :: env_object
  def copy_xy(
        %{position: %{x: x, y: y}},
        %{position: %{path: [_ | rest]} = position} = o
      ) do
    %{o | position: %{position | x: x, y: y, path: rest}}
  end

  @spec enter(t(), env_object) :: enter_result
  def enter(%__MODULE__{enter?: false}, %Tank{}), do: {:error, :forbidden}

  def enter(%__MODULE__{enter?: false, health: :infinite}, %Bullet{} = bullet),
    do: {:ok, %{bullet | dead?: true}}

  def enter(
        %__MODULE__{enter?: false, health: health, position: p},
        %Bullet{__callbacks__: callbacks, position: bp} = bullet
      )
      when is_integer(health) and health > 0 do
    callback = %ContextCallback{
      action: :damage_environment,
      value: %{
        x: p.x,
        y: p.y,
        direction: bp.direction,
        power: bullet.power,
        reinforced?: bullet.reinforced?
      }
    }

    {:ok, %{bullet | dead?: true, __callbacks__: [callback | callbacks]}}
  end

  def enter(%__MODULE__{__module__: module} = environment, o) do
    module.handle_enter(environment, o)
  end

  @spec leave(t(), env_object) :: enter_result
  def leave(%__MODULE__{__module__: module} = environment, o) do
    module.handle_leave(environment, o)
  end

  @spec handle_hit(t(), map()) :: {atom, t()}
  def handle_hit(%__MODULE__{health: 0} = e, _) do
    {:ignore1, e}
  end

  def handle_hit(%__MODULE__{health: :infinity} = e, _), do: {:ignore2, e}

  def handle_hit(%__MODULE__{solid?: true} = e, %{reinforced?: false}), do: {:solid, e}

  def handle_hit(%__MODULE__{health: health} = e, %{power: power}) when health <= power do
    {:reset, reset(e, BattleCity.Environment.Blank)}
  end

  def handle_hit(%__MODULE__{health: health} = e, %{power: power, direction: direction}) do
    {:reduce, normalize(e, {health - power, direction})}
  end

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

  @shape_direction_2_map %{
    up: :top,
    down: :bottom,
    right: :right,
    left: :left
  }

  @spec normalize(t(), {integer, Position.direction()}) :: t()
  defp normalize(%__MODULE__{shape: :full} = env, {2, direction}) do
    %{env | health: 2, shape: @shape_direction_2_map[direction]}
  end

  defp normalize(%__MODULE__{} = env, {1, direction}) do
    %{env | health: 1, shape: @shape_direction_2_map[direction]}
  end

  @health_map %{
    full: 4,
    top: 2,
    bottom: 2,
    left: 2,
    right: 2,
    left_bottom: 1,
    right_bottom: 1
  }
  def handle_init(%{shape: shape} = map),
    do: Map.put(map, :health, Map.fetch!(@health_map, shape))
end

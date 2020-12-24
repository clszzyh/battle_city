defmodule BattleCity.Tank do
  @moduledoc """
  Tank
  """

  alias BattleCity.Bullet
  alias BattleCity.Business.Generate
  alias BattleCity.Callback
  alias BattleCity.Config
  alias BattleCity.Context
  alias BattleCity.Position
  alias BattleCity.Process.GameSupervisor
  alias __MODULE__

  @type health :: 1..10
  @type points :: integer

  defmodule Base do
    @moduledoc """
    Base Tank
    """

    @type t :: %__MODULE__{
            __module__: module,
            level: BattleCity.level(),
            points: Tank.points(),
            health: Tank.health(),
            move_speed: Position.speed(),
            bullet_speed: Position.speed()
          }

    @enforce_keys [:level, :points, :health, :move_speed, :bullet_speed]

    defstruct [
      :__module__,
      :level,
      :points,
      :health,
      :move_speed,
      :bullet_speed
    ]

    use BattleCity.StructCollect

    @callback handle_level_up(Tank.t()) :: module()

    @callback new() :: Tank.t()
    @callback new(map) :: Tank.t()

    defmacro __using__(opt \\ []) do
      obj = struct(__MODULE__, opt)
      keys = Map.keys(Tank.__struct__())

      quote location: :keep do
        alias BattleCity.Tank

        @impl true
        def handle_level_up(_), do: nil

        @impl true
        def new(map \\ %{}) do
          meta = init(map)

          data = %{
            __module__: __MODULE__,
            meta: meta,
            position:
              Position.init(
                map
                |> Map.merge(%{__parent__: unquote(__MODULE__), __module__: __MODULE__})
              ),
            speed: meta.move_speed * Position.speed(),
            health: meta.health
          }

          struct!(Tank, map |> Map.take(unquote(keys)) |> Map.merge(data))
        end

        init_ast(unquote(__MODULE__), __MODULE__, unquote(Macro.escape(obj)), unquote(opt))
      end
    end
  end

  @type t :: %__MODULE__{
          __module__: module(),
          meta: Base.t(),
          id: BattleCity.id(),
          __callbacks__: [Callback.t()],
          position: Position.t(),
          speed: Position.speed(),
          lifes: integer(),
          score: integer(),
          health: health(),
          reason: BattleCity.reason(),
          enemy?: boolean(),
          hidden?: boolean(),
          shield?: boolean(),
          moving?: boolean(),
          freezed?: boolean(),
          shootable?: boolean(),
          changed?: boolean(),
          dead?: boolean()
        }

  @enforce_keys [:meta, :__module__, :position]
  @derive {SimpleDisplay, only: [:id, :__module__, :speed, :health, :score, :lifes]}
  defstruct [
    :__module__,
    :meta,
    :id,
    :reason,
    :position,
    :speed,
    :health,
    score: 0,
    dead?: false,
    shield?: false,
    enemy?: true,
    shootable?: true,
    hidden?: false,
    moving?: false,
    changed?: true,
    freezed?: false,
    __callbacks__: [],
    lifes: Config.get(:life_count)
  ]

  use BattleCity.Callback

  @ai_modules [BattleCity.Ai.Simple, BattleCity.Ai.FindHome]

  @impl true
  def handle_callback(%{action: :create}, %__MODULE__{enemy?: true, id: id}, ctx) do
    {_, _} =
      GameSupervisor.start_tank(
        ctx.slug,
        %{
          id: id,
          __module__: Enum.random(@ai_modules),
          interval: ctx.bot_loop_interval,
          loop: Context.bot_loop(ctx)
        }
      )

    ctx
  end

  def handle_callback(%{action: :delete}, %__MODULE__{enemy?: true, id: id}, ctx) do
    {:ok, _reason} = GameSupervisor.stop_tank(ctx.slug, id)
    fn ctx -> ctx |> Generate.add_bot(%{bot_count: 1}) end
  end

  def handle_callback(_, _, ctx), do: ctx

  @spec hit(t(), Bullet.t()) :: t()
  def hit(%__MODULE__{health: health} = tank, %Bullet{power: power}) when power < health do
    %__MODULE__{tank | health: health - power}
  end

  def hit(%__MODULE__{} = tank, %Bullet{}), do: %{tank | dead?: true}
end
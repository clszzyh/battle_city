defmodule BattleCity.Stage do
  @moduledoc """
  Stage
  """

  alias BattleCity.Compile
  alias BattleCity.Environment
  alias BattleCity.Position

  @type bots :: [{atom(), integer()}]
  @type map_data :: %{Position.coordinate() => Environment.t()}

  @type t :: %__MODULE__{
          __module__: module,
          name: binary(),
          difficulty: integer(),
          map: map_data,
          bots: bots
        }

  @derive {Inspect, except: [:map]}
  @derive {SimpleDisplay, only: [:name, :difficulty, :__module__]}
  @enforce_keys [:name, :difficulty, :map, :bots]
  defstruct [
    :__module__,
    :name,
    :difficulty,
    :map,
    :bots
  ]

  use BattleCity.StructCollect

  @callback name :: binary()

  defmacro __using__(opt) do
    # raw = Keyword.fetch!(opt, :map)
    obj = struct!(__MODULE__, Compile.validate_stage!(Map.new(opt)))

    raw = for i <- 0..12, do: for(j <- 0..12, do: obj.map[{i * 2, j * 2}])

    quote location: :keep do
      @impl true
      def name, do: unquote(String.to_integer(opt[:name]))
      def __map__, do: unquote(Macro.escape(obj.map))
      def __raw__, do: unquote(Macro.escape(raw))

      init_ast(unquote(__MODULE__), __MODULE__, unquote(Macro.escape(obj)), unquote(opt))

      @after_compile unquote(__MODULE__)
    end
  end

  def __after_compile__(_env, _bytecode) do
    # StageCache.put_stage(env.module)
  end
end

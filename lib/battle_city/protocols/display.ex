defmodule BattleCity.Display do
  @moduledoc false

  @spec columns(ComplexDisplay.t(), keyword()) :: keyword
  def columns(o, opts \\ []) do
    SimpleDisplay.columns(o) ++ ComplexDisplay.columns(o, Map.new(opts))
  end
end

# defprotocol Grid do
#   @spec grid(t) :: BattleCity.Context.grid()
#   def grid(struct)
# end

# defimpl Grid, for: Any do
#   defmacro __deriving__(module, _, color: color) do
#     quote do
#       defimpl Grid, for: unquote(module) do
#         def grid(%{position: %{x: x, y: y}}) do
#           {x, y, 1.9, 1.9, unquote(color)}
#         end

#         def grid(%{x: x, y: y}) do
#           {x, y, 1.9, 1.9, unquote(color)}
#         end
#       end
#     end
#   end

#   def grid(_), do: nil
# end

# defprotocol Size do
#   @spec width(t) :: BattleCity.Position.width()
#   def width(struct)

#   @spec height(t) :: BattleCity.Position.height()
#   def height(struct)
# end
# defimpl Size, for: Any do
#   defmacro __deriving__(module, _, width: width, height: height) do
#     quote do
#       defimpl Size, for: unquote(module) do
#         def width(_), do: unquote(width)
#         def height(_), do: unquote(height)
#       end
#     end
#   end
#   def width(_), do: nil
#   def height(_), do: nil
# end

defprotocol SimpleDisplay do
  @fallback_to_any true

  @spec columns(t) :: keyword
  def columns(struct)
end

defimpl SimpleDisplay, for: Any do
  defmacro __deriving__(module, _, only: [_ | _] = only) do
    quote do
      defimpl SimpleDisplay, for: unquote(module) do
        def columns(arg) do
          for i <- unquote(only), do: {i, Map.fetch!(arg, i)}
        end
      end
    end
  end

  def columns(_), do: []
end

defprotocol ComplexDisplay do
  @spec columns(t, map) :: keyword
  def columns(struct, opts)
end

defimpl ComplexDisplay, for: BattleCity.Context do
  def columns(%{} = o, %{stage_fn: stage_fn} = m) when is_function(stage_fn) do
    columns(o, %{m | stage_fn: nil}) ++ [stage: stage_fn.(o.stage.name)]
  end

  def columns(%{} = o, %{tank_fn: tank_fn} = m) when is_function(tank_fn) do
    tanks =
      o.tanks
      |> Enum.map(fn {id, %{position: p, __module__: module}} ->
        x = String.pad_leading(to_string(p.x), 2)
        y = String.pad_leading(to_string(p.y), 2)
        name = String.pad_leading(to_string(module.name()), 6)
        tank_fn.("{#{x} , #{y}} [#{name}] -> #{id}", id)
      end)
      |> Enum.intersperse({:safe, "<br />"})

    columns(o, %{m | tank_fn: nil}) ++ [tanks: tanks]
  end

  def columns(%{} = o, _) do
    [
      objects: o.objects |> Map.values() |> Enum.map(&map_size/1) |> Enum.sum(),
      power_ups: Enum.count(o.power_ups),
      bullets: Enum.count(o.bullets)
    ]
  end
end

defimpl ComplexDisplay, for: BattleCity.Stage do
  ## TODO environment_fn click
  def columns(%{__module__: module} = o, %{environment_fn: environment_fn} = m)
      when is_function(environment_fn) do
    raw =
      module.__raw__()
      |> Enum.map(fn x ->
        Enum.map_join(x, " ", fn a ->
          String.pad_leading(a.raw, 2)
        end)
      end)
      |> Enum.intersperse({:safe, "<br />"})

    columns(o, %{m | environment_fn: nil}) |> Keyword.put(:raw, raw)
  end

  ## TODO display from module
  def columns(%{} = o, _) do
    [
      bots: o.bots |> Enum.map_join(", ", fn {m, c} -> "#{m.name()} -> #{c}" end),
      raw: "raw"
    ]
  end
end

defimpl ComplexDisplay, for: BattleCity.Tank do
  def columns(%{}, _) do
    []
  end
end

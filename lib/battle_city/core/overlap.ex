defmodule BattleCity.Core.Overlap do
  @moduledoc false

  alias BattleCity.Context
  alias BattleCity.Position
  alias BattleCity.PowerUp
  alias BattleCity.Tank

  @typep f :: {Object.t(), Object.value()}
  @typep resolve_args :: {Position.coordinate(), f(), f()}

  @spec resolve(Context.t()) :: Context.t()
  def resolve(%Context{objects: objects} = ctx) do
    objects
    |> Enum.flat_map(fn {xy, %{} = map} ->
      for {i, iv} <- map,
          {j, jv} <- map,
          i != j,
          uniq: true,
          do: {xy, Map.new([{i, iv}, {j, jv}])}
    end)
    |> Enum.map(fn {xy, mapset} ->
      [a, b | []] = Map.to_list(mapset)
      {xy, a, b}
    end)
    |> Enum.reduce(ctx, &do_resolve/2)
  end

  ### tank > power_ups > bullet
  @spec do_resolve(resolve_args, Context.t()) :: Context.t()
  defp do_resolve({o, {%{type: :b}, _} = f1, {%{type: :p}, _} = f2}, ctx),
    do: do_resolve({o, f2, f1}, ctx)

  defp do_resolve({o, {%{type: :p}, _} = f1, {%{type: :t}, _} = f2}, ctx),
    do: do_resolve({o, f2, f1}, ctx)

  defp do_resolve({o, {%{type: :b}, _} = f1, {%{type: :t}, _} = f2}, ctx),
    do: do_resolve({o, f2, f1}, ctx)

  defp do_resolve({_, {%{type: :t}, _}, {%{type: :t}, _}}, ctx), do: ctx
  defp do_resolve({_, {%{type: :p}, _}, {%{type: :p}, _}}, ctx), do: ctx
  defp do_resolve({_, {%{type: :b}, _}, {%{type: :b}, _}}, ctx), do: ctx

  defp do_resolve({_, {%{type: :b, enemy?: b}, _}, {%{type: :b, enemy?: b}, _}}, ctx), do: ctx

  defp do_resolve(
         {_, {%{type: :b, id: bid1}, _}, {%{type: :b, id: bid2}, _}},
         %{bullets: bullets} = ctx
       )
       when is_map_key(bullets, bid1) and is_map_key(bullets, bid2) do
    ctx |> Context.delete_object(:bullets, bid1) |> Context.delete_object(:bullets, bid2)
  end

  defp do_resolve({_, {%{type: :t, enemy?: b}, _}, {%{type: :b, enemy?: b}, _}}, ctx), do: ctx

  defp do_resolve(
         {_, {%{type: :t, id: tid}, _}, {%{type: :b, id: bid}, _}},
         %{bullets: bullets, tanks: tanks} = ctx
       )
       when is_map_key(bullets, bid) and is_map_key(tanks, tid) do
    bullet = Context.fetch_object!(ctx, :bullets, bid)

    {:ok, ctx, _tank} =
      Context.update_object_and_ctx!(ctx, :tanks, tid, &Tank.handle_hit/3, [bullet])

    ctx |> Context.delete_object(:bullets, bid)
  end

  defp do_resolve(
         {_, {%{type: :t, id: tid}, _}, {%{type: :p, id: pid}, _}},
         %{tanks: tanks, power_ups: power_ups} = ctx
       )
       when is_map_key(tanks, tid) and is_map_key(power_ups, pid) do
    power_up = Context.fetch_object!(ctx, :power_ups, pid)

    {result, ctx, _tank} =
      Context.update_object_and_ctx!(ctx, :tanks, tid, &PowerUp.add/3, [power_up])

    case result do
      {:later, f} -> Context.update_object_raw!(ctx, :power_ups, pid, f)
      _ -> Context.delete_object(ctx, :power_ups, pid)
    end
  end

  defp do_resolve(_, ctx), do: ctx
end

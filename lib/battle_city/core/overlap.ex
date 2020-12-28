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

  defp do_resolve({_, {%{type: :b, id: bid1}, _}, {%{type: :b, id: bid2}, _}}, ctx) do
    ctx |> Context.delete_object(:bullets, bid1) |> Context.delete_object(:bullets, bid2)
  end

  defp do_resolve({_, {%{type: :t, enemy?: b}, _}, {%{type: :b, enemy?: b}, _}}, ctx), do: ctx

  defp do_resolve({_, {%{type: :t, id: tid}, _}, {%{type: :b, id: bid}, _}}, ctx) do
    bullet = Context.fetch_object!(ctx, :bullets, bid)
    tank = Context.fetch_object!(ctx, :tanks, tid)
    tank = Tank.handle_hit(tank, bullet)
    ctx |> Context.delete_object(:bullets, bid) |> Context.put_object(tank)
  end

  defp do_resolve({_, {%{type: :t, id: tid}, _}, {%{type: :p, id: pid}, _}}, ctx) do
    power_up = Context.fetch_object!(ctx, :power_ups, pid)
    tank = Context.fetch_object!(ctx, :tanks, tid)
    {ctx, tank, power_up_f} = PowerUp.add(ctx, tank, power_up)

    if power_up_f do
      ctx |> Context.update_object_raw!(:power_ups, pid, power_up_f) |> Context.put_object(tank)
    else
      ctx |> Context.delete_object(:power_ups, pid) |> Context.put_object(tank)
    end
  end
end

defmodule BattleCity.Business.Batch do
  @moduledoc false

  alias BattleCity.Business
  alias BattleCity.Context
  alias BattleCity.Tank

  @type op :: :kill | :stop | :resume

  @spec handle_all_enemies(Context.t(), Tank.t(), {op(), BattleCity.reason()}) :: Context.t()
  def handle_all_enemies(
        %Context{tanks: tanks} = ctx,
        %Tank{id: id} = tank,
        {op, reason}
      ) do
    {tanks, {ctx, tank}} =
      Enum.map_reduce(tanks, {ctx, tank}, fn {_id, target}, {ctx, tank} ->
        reduce_op(op, target, ctx, tank, reason)
      end)

    tanks = Enum.into(tanks, %{}, &{&1.id, &1}) |> Map.put(id, tank)

    %{ctx | tanks: tanks}
  end

  @spec reduce_op(op(), Tank.t(), Context.t(), Tank.t(), BattleCity.reason()) ::
          {Tank.t(), {Context.t(), Tank.t()}}
  defp reduce_op(
         _,
         %Tank{enemy?: enemy?} = target,
         %Context{} = ctx,
         %Tank{enemy?: enemy?} = tank,
         _
       ) do
    {target, {ctx, tank}}
  end

  defp reduce_op(:stop, %Tank{} = target, %Context{} = ctx, tank, _) do
    {%{target | freezed?: true}, {ctx, tank}}
  end

  defp reduce_op(:resume, %Tank{} = target, %Context{} = ctx, tank, _) do
    {%{target | freezed?: false}, {ctx, tank}}
  end

  defp reduce_op(
         :kill,
         %Tank{meta: %{points: points}} = target,
         %Context{} = ctx,
         %Tank{} = tank,
         reason
       ) do
    target = %{target | dead?: true, reason: reason}
    tank = Business.Score.add_score(tank, points, reason)

    {target, {ctx, tank}}
  end
end

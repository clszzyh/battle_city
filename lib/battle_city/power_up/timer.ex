defmodule BattleCity.PowerUp.Timer do
  @moduledoc false

  use BattleCity.PowerUp

  @impl true
  def handle_add(%Context{} = ctx, %Tank{} = tank) do
    ctx = Core.Batch.handle_all_enemies(ctx, tank, {:stop, :timer})
    {ctx, tank}
  end

  @impl true
  def handle_remove(%Context{} = ctx, %Tank{} = tank) do
    ctx = Core.Batch.handle_all_enemies(ctx, tank, {:resume, :timer})
    {ctx, tank}
  end
end

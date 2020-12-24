defmodule BattleCity.PowerUp.Timer do
  @moduledoc false

  use BattleCity.PowerUp

  @impl true
  def handle_on(%Context{} = ctx, %Tank{} = tank) do
    Business.Batch.handle_all_enemies(ctx, tank, {:stop, :timer})
  end

  @impl true
  def handle_off(%Context{} = ctx, %Tank{} = tank) do
    Business.Batch.handle_all_enemies(ctx, tank, {:resume, :timer})
  end
end

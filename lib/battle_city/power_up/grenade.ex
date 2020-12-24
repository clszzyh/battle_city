defmodule BattleCity.PowerUp.Grenade do
  @moduledoc false

  use BattleCity.PowerUp, duration: :instant

  @impl true
  def handle_on(%Context{} = ctx, %Tank{} = tank) do
    Business.Batch.handle_all_enemies(ctx, tank, {:kill, :grenade})
  end
end

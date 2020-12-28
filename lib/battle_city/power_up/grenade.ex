defmodule BattleCity.PowerUp.Grenade do
  @moduledoc false

  use BattleCity.PowerUp, duration: :instant

  @impl true
  def handle_add(%Context{} = ctx, %Tank{} = tank) do
    ctx = Core.Batch.handle_all_enemies(ctx, tank, {:kill, :grenade})
    {ctx, tank}
  end
end

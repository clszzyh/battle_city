defmodule BattleCity.PowerUp.Life do
  @moduledoc false

  use BattleCity.PowerUp, duration: :instant

  @impl true
  def handle_add(%Context{} = ctx, %Tank{lifes: lifes} = tank) do
    {ctx, %{tank | lifes: lifes + 1}}
  end
end

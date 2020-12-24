defmodule BattleCity.PowerUp.Life do
  @moduledoc false

  use BattleCity.PowerUp, duration: :instant

  @impl true
  def handle_on(%Context{}, %Tank{lifes: lifes} = tank) do
    %{tank | lifes: lifes + 1}
  end
end

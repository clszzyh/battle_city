defmodule BattleCity.PowerUp.Helmet do
  @moduledoc false

  use BattleCity.PowerUp

  @impl true
  def handle_on(%Context{}, %Tank{} = tank) do
    %{tank | shield?: true}
  end

  @impl true
  def handle_off(%Context{}, %Tank{} = tank) do
    %{tank | shield?: false}
  end
end

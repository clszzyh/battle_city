defmodule BattleCity.PowerUp.Shovel do
  @moduledoc false

  use BattleCity.PowerUp

  @impl true
  def handle_add(%Context{} = ctx, %Tank{} = tank) do
    {%{ctx | shovel?: true}, tank}
  end

  @impl true
  def handle_remove(%Context{} = ctx, %Tank{} = tank) do
    {%{ctx | shovel?: false}, tank}
  end
end

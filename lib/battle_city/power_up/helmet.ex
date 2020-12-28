defmodule BattleCity.PowerUp.Helmet do
  @moduledoc false

  use BattleCity.PowerUp

  @impl true
  def handle_add(%Context{} = ctx, %Tank{} = tank) do
    {ctx, %{tank | shield?: true}}
  end

  @impl true
  def handle_remove(%Context{} = ctx, %Tank{} = tank) do
    {ctx, %{tank | shield?: false}}
  end
end

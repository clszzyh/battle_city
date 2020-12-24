defmodule BattleCity.PowerUp.Shovel do
  @moduledoc false

  use BattleCity.PowerUp

  @impl true
  def handle_on(%Context{} = ctx, %Tank{}) do
    %{ctx | shovel?: true}
  end

  @impl true
  def handle_off(%Context{} = ctx, %Tank{}) do
    %{ctx | shovel?: false}
  end
end

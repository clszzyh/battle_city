defmodule BattleCity.Environment.SteelWall do
  @moduledoc false

  use BattleCity.Environment, enter?: false

  @impl true
  def handle_init(map), do: Environment.handle_init(map)
end

defmodule BattleCity.Environment.BrickWall do
  @moduledoc false

  use BattleCity.Environment, solid?: true, enter?: false

  @impl true
  def handle_init(map), do: Environment.handle_init(map)
end

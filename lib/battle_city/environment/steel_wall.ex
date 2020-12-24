defmodule BattleCity.Environment.SteelWall do
  @moduledoc false

  use BattleCity.Environment,
    health: 4,
    enter?: false

  # @shape_map %{
  #   "f" => 1,
  #   "3" => 2,
  #   "c" => 3,
  #   "5" => 4,
  #   "a" => 5
  # }

  # @shapes Map.keys(@shape_map)
end

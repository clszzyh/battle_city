defmodule BattleCity.Tank.Power do
  @moduledoc false

  use BattleCity.Tank.Base,
    points: 300,
    health: 1,
    move_speed: 2,
    bullet_speed: 3,
    level: 3

  @impl true
  def handle_level_up(_), do: Tank.Armor
end

defmodule BattleCity.Tank.Fast do
  @moduledoc false

  use BattleCity.Tank.Base,
    points: 200,
    health: 1,
    move_speed: 3,
    bullet_speed: 2,
    level: 2

  @impl true
  def handle_level_up(_), do: Tank.Power
end

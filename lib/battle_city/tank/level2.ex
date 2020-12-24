defmodule BattleCity.Tank.Level2 do
  @moduledoc false

  use BattleCity.Tank.Base,
    points: 4000,
    health: 1,
    move_speed: 3,
    bullet_speed: 3,
    level: 2

  @impl true
  def handle_level_up(_), do: Tank.Level3
end

defmodule BattleCity.Tank.Level1 do
  @moduledoc false

  use BattleCity.Tank.Base,
    points: 4000,
    health: 1,
    move_speed: 2,
    bullet_speed: 2,
    level: 1

  @impl true
  def handle_level_up(_), do: Tank.Level2
end

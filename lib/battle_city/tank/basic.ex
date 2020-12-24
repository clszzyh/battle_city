defmodule BattleCity.Tank.Basic do
  @moduledoc false

  use BattleCity.Tank.Base,
    points: 100,
    health: 1,
    move_speed: 1,
    bullet_speed: 1,
    level: 1

  @impl true
  def handle_level_up(_), do: Tank.Fast
end

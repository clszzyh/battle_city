defmodule BattleCity.Config do
  @moduledoc false

  @default_map %{
    life_count: 3,
    rest_enemies: 20,
    power_up_duration: 10,
    telemetry_logger: false,
    telemetry_logger_level: :debug
  }

  @config_keys Map.keys(@default_map)

  def get(key) when key in @config_keys do
    Application.get_env(:battle_city, key, Map.fetch!(@default_map, key))
  end
end

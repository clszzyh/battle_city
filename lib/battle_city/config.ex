defmodule BattleCity.Config do
  @moduledoc false

  @default_map %{
    life_count: 3,
    rest_enemies: 20,
    power_up_duration: 10,
    telemetry_logger: true,
    telemetry_logger_level: :debug
  }

  def get(key) when is_map_key(@default_map, key) do
    Application.get_env(:battle_city, key, Map.fetch!(@default_map, key))
  end

  def get(key, default), do: Application.get_env(:battle_city, key, default)
end

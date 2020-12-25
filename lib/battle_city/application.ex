defmodule BattleCity.Application do
  @moduledoc false

  use Application

  alias BattleCity.Config
  alias BattleCity.Process

  def start(_type, _args) do
    if Config.get(:telemetry_logger) do
      :ok = BattleCity.Telemetry.attach_default_logger(Config.get(:telemetry_logger_level))
    end

    {:ok, _pid} =
      Supervisor.start_link(
        [
          Process.ProcessRegistry,
          Process.GameDynamicSupervisor
        ],
        strategy: :one_for_one,
        name: BattleCity.Supervisor
      )
  end
end

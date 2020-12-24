defmodule BattleCity.Process.TankDynamicSupervisor do
  @moduledoc false

  use DynamicSupervisor
  use BattleCity.Process.ProcessRegistry
  alias BattleCity.Process.TankServer

  require Logger

  def start_link({slug, args}) do
    DynamicSupervisor.start_link(__MODULE__, {slug, args}, name: via_tuple(slug))
  end

  @impl true
  def init({slug, _args}) do
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [slug])
  end

  def tank_process(srv, args) do
    case start_child_tank(srv, args) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  def terminate_child_tank(srv, key) do
    pid = TankServer.pid(key)

    Logger.info("delete tank: #{inspect(pid)}, #{inspect(key)}")

    if pid do
      DynamicSupervisor.terminate_child(srv, pid)
      |> case do
        :ok -> {:ok, pid}
        err -> err
      end
    else
      {:error, "Not found #{inspect(key)}"}
    end
  end

  defp start_child_tank(srv, args) do
    DynamicSupervisor.start_child(srv, {TankServer, args})
  end

  def children(srv) do
    childs = DynamicSupervisor.which_children(srv)
    for {_, pid, :worker, [module]} <- childs, do: %{pid: pid, module: module}
  end
end

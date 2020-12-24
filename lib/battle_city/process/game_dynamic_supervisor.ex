defmodule BattleCity.Process.GameDynamicSupervisor do
  @moduledoc false

  alias BattleCity.Process.GameSupervisor

  use DynamicSupervisor
  require Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec server_process(BattleCity.slug(), map()) :: pid()
  def server_process(slug, opts \\ %{}) do
    case start_child(slug, opts) do
      {:ok, pid} ->
        pid

      {:error, {:already_started, pid}} ->
        pid

      # {:error, {:shutdown, {:failed_to_start_child, _, {:already_started, pid}}}} ->
      #   pid

      other ->
        Logger.error("#{slug}, #{inspect(opts)}, #{inspect(other)}")
        nil
    end
  end

  defp start_child(slug, opts) do
    DynamicSupervisor.start_child(__MODULE__, {GameSupervisor, {slug, opts}})
  end

  @spec terminate_child(BattleCity.slug()) :: :ok | {:error, BattleCity.reason()}
  def terminate_child(slug) do
    GameSupervisor.pid(slug)
    |> case do
      nil ->
        {:error, :not_found_srv}

      pid ->
        Logger.info("terminate server: #{slug} -> #{pid}")
        DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end

  def children do
    childs = DynamicSupervisor.which_children(__MODULE__)
    for {_, pid, kind, [module]} <- childs, do: %{pid: pid, kind: kind, module: module}
  end
end

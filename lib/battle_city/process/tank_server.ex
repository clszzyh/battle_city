defmodule BattleCity.Process.TankServer do
  @moduledoc false

  use GenServer
  use BattleCity.Process.ProcessRegistry

  alias BattleCity.Ai
  alias BattleCity.Context
  alias BattleCity.Game

  def refresh(srv), do: GenServer.cast(srv, :refresh)
  def state(srv), do: GenServer.call(srv, :state)

  def start_link(slug, %{id: id} = opts) do
    GenServer.start_link(__MODULE__, {slug, opts}, name: via_tuple({slug, id}))
  end

  @impl true
  def init({slug, opts}) do
    {:ok, struct!(Ai, Map.put(opts, :slug, slug)), {:continue, :loop}}
  end

  @impl true
  def handle_call(:state, _, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:refresh, %{slug: slug} = state) do
    {srv, ctx} = Game.ctx(slug)
    {:noreply, %{state | pid: srv, loop: Context.bot_loop(ctx)}, {:continue, :loop}}
  end

  @impl true
  def handle_info(:loop, state) do
    state = Game.loop_bot(state)
    _ = do_loop(state)
    {:noreply, state}
  end

  @impl true
  def handle_continue(:loop, state) do
    _ = do_loop(state)
    {:noreply, state}
  end

  @impl true
  def terminate(reason, _state) do
    IO.puts("terminate tank: #{inspect(reason)}")
    {:ok, reason}
  end

  defp do_loop(%Ai{loop: false}), do: :ok
  defp do_loop(state), do: Process.send_after(self(), :loop, state.interval)
end

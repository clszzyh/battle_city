defmodule BattleCity.ProcessTest do
  use ExUnit.Case, async: true

  doctest BattleCity.Process.ProcessRegistry

  alias BattleCity.Process.GameDynamicSupervisor
  alias BattleCity.Process.GameServer
  alias BattleCity.Process.ProcessRegistry
  alias BattleCity.Process.TankDynamicSupervisor

  @moduletag :process

  setup_all do
    []
  end

  test "server process", %{} do
    bob_pid = GameDynamicSupervisor.server_process("bob")
    alice_pid = GameDynamicSupervisor.server_process("alice")
    assert bob_pid != alice_pid
    bob_srv = GameServer.pid("bob")
    ctx = GameServer.invoke_call(bob_srv, :ctx)
    assert bob_srv != bob_pid
    assert ProcessRegistry.pid({GameServer, "bob"}) == bob_srv
    assert ctx.slug == "bob"
    assert bob_pid == GameDynamicSupervisor.server_process("bob")

    tank_srv = ProcessRegistry.pid({TankDynamicSupervisor, "bob"})
    tank_children = TankDynamicSupervisor.children(tank_srv)
    assert Enum.count(tank_children) == 4
  end

  # test "kill", %{} do
  #   foo_pid = GameDynamicSupervisor.server_process("foo")
  #   Process.exit(foo_pid, :kill)
  #   ctx = "foo" |> GameDynamicSupervisor.server_process() |> GameServer.invoke_call(:ctx)
  #   assert ctx.slug == "foo"
  # end
end

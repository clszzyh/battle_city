defmodule BattleCity.GameTest do
  use ExUnit.Case, async: true

  # alias BattleCity.Process.GameDynamicSupervisor
  alias BattleCity.Context
  alias BattleCity.Event
  alias BattleCity.Game
  alias BattleCity.Position
  # alias BattleCity.Process.GameServer
  # alias BattleCity.Process.ProcessRegistry
  alias BattleCity.Process.TankServer

  @moduletag :game

  setup_all do
    []
  end

  @tag :shootable
  test "concurrency", %{} do
    slug = "concurrency"
    name = "bar"

    opts = %{
      player_name: name,
      mock: true,
      bot_count: 1,
      enable_bot: false,
      stage: 0
    }

    {_pid, _ctx} = Game.start_server(slug, opts)
    for _ <- 0..200, do: Game.invoke_call(slug, :real_loop)
    {:ok, ctx} = Game.invoke_call(slug, :loop)

    assert Enum.count(ctx.bullets) ==
             Enum.count(Enum.filter(ctx.tanks, &match?({_, %{shootable?: false}}, &1)))
  end

  test "shootable?", %{} do
    slug = "shootable?"
    name = "bar"

    opts = %{
      player_name: name,
      mock: true,
      bot_count: 1,
      enable_bot: false,
      enemy_x: 0,
      enemy_y: 0,
      stage: 0
    }

    {_pid, ctx} = Game.start_server(slug, opts)
    assert ctx.stage.name == "0"
    assert ctx.rest_enemies == 19
    {:ok, ctx} = Game.start_event(ctx, %Event{name: :shoot, id: name})
    assert Enum.count(Context.non_empty_objects(ctx)) == 3
    assert ctx.__counters__.bullet == 1
    refute Context.fetch_object!(ctx, :t, name).shootable?
    {:ok, ctx} = Game.invoke_call(slug, {:loop, 100})
    assert Context.fetch_object!(ctx, :t, name).shootable?
    assert Context.fetch_object!(ctx, :t, name).speed == 2

    tank = TankServer.pid({slug, "e0"})
    assert Process.alive?(tank)

    {:ok, ctx} =
      Game.invoke_call(
        slug,
        {:plug,
         fn ctx ->
           ctx = Context.update_object_raw!(ctx, :tanks, name, fn t -> {t, %{t | speed: 200}} end)
           {:ok, ctx}
         end}
      )

    assert Context.fetch_object!(ctx, :t, name).speed == 200
    assert Enum.count(Context.non_empty_objects(ctx)) == 2
    {:ok, ctx} = Game.start_event(ctx, %Event{name: :move, value: :up, id: name})
    assert Context.fetch_object!(ctx, :t, name).position.y == 24
    {:ok, ctx} = Game.invoke_call(slug, {:loop, 1})
    assert Enum.count(Context.non_empty_objects(ctx)) == 2
    assert Context.fetch_object!(ctx, :t, name).position.y == 0

    {:ok, ctx} =
      Game.invoke_call(
        slug,
        {:plug,
         fn ctx ->
           ctx = Context.update_object_raw!(ctx, :tanks, name, fn t -> {t, %{t | speed: 2}} end)
           {:ok, ctx}
         end}
      )

    {:ok, ctx} = Game.start_event(ctx, %Event{name: :move, value: :left, id: name})
    {:ok, ctx} = Game.start_event(ctx, %Event{name: :shoot, id: name})
    refute Context.fetch_object!(ctx, :t, name).shootable?
    assert Enum.count(ctx.bullets) == 1
    assert ctx.__counters__.bullet == 2
    assert ctx.bullets["b1"].position.x == Context.fetch_object!(ctx, :t, name).position.x
    assert ctx.bullets["b1"].position.y == Context.fetch_object!(ctx, :t, name).position.y
    assert ctx.tanks["e0"].position.x == 0
    assert ctx.tanks["e0"].position.y == 0
    assert map_size(ctx.objects[{0, 0}]) == 1
    assert Enum.count(Context.non_empty_objects(ctx)) == 3

    # IO.inspect({Context.non_empty_objects(ctx), ctx.__counters__})
    {:ok, ctx} = Game.invoke_call(slug, {:loop, 100})
    # IO.inspect({Context.non_empty_objects(ctx), ctx.__counters__})
    assert Enum.empty?(ctx.bullets)
    # assert Enum.empty?(ctx.objects[{0, 0}])
    assert Context.fetch_object!(ctx, :t, name).shootable?
    refute Process.alive?(tank)
    assert is_nil(ctx.tanks["e0"])

    assert ctx.rest_enemies == 18
    assert ctx.mock
    tank = TankServer.pid({slug, "e1"})
    assert Process.alive?(tank)
    refute TankServer.state(tank).loop
    assert Enum.count(Context.object_grids(ctx)) == 2
    assert ctx.tanks["e1"] != nil
    # {:ok, ctx} = Game.start_event(ctx, %Event{name: :move, id: name})
  end

  test "enemy", %{} do
    slug = "enemy"
    name = "bar"

    {x, y} = {0, Position.size() * Position.atom()}

    opts = %{player_name: name, mock: true, bot_count: 1, enemy_x: x, enemy_y: y}
    {_pid, ctx} = Game.start_server(slug, opts)
    refute Enum.empty?(ctx.objects[{x, y}])
    {:ok, ctx} = Game.start_event(ctx, %Event{name: :move, value: :left, id: name})
    {:ok, ctx} = Game.start_event(ctx, %Event{name: :shoot, id: name})
    refute Context.fetch_object!(ctx, :t, name).shootable?
    refute Context.fetch_object!(ctx, :t, "e0").dead?

    tank = TankServer.pid({slug, "e0"})
    assert Process.alive?(tank)
    # Process.send(tank, :loop, [])

    grids = Context.object_grids(ctx)
    assert Enum.count(grids) == 2 + 1
    assert Enum.count(ctx.bullets) == 1
    {:ok, ctx} = Game.invoke_call(slug, {:loop, 100})
    assert Enum.empty?(ctx.bullets)
    assert Context.fetch_object!(ctx, :t, name).shootable?
    assert Context.fetch_object(ctx, :t, "e0") == nil
    assert Enum.empty?(ctx.objects[{x, y}])
    refute Process.alive?(tank)
  end

  test "left bullet", %{} do
    slug = "left bullet"
    name = "bar"
    {_pid, ctx} = Game.start_server(slug, %{player_name: name, mock: true})

    {:ok, ctx} = Game.start_event(ctx, %Event{name: :move, value: :left, id: name})
    {:ok, ctx} = Game.start_event(ctx, %Event{name: :shoot, id: name})
    grids = Context.object_grids(ctx)
    assert Enum.count(grids) == 5 + 1
    assert Enum.count(ctx.bullets) == 1
    {:ok, ctx} = Game.invoke_call(slug, {:loop, 100})
    assert Enum.empty?(ctx.bullets)
    grids = Context.object_grids(ctx)
    assert Enum.count(grids) == 5
  end

  test "pause and move", %{} do
    slug = "foo"
    name = "bar"
    {_pid, ctx} = Game.start_server(slug, %{player_name: name, mock: true})
    assert ctx.slug == slug
    assert ctx.state == :started
    assert Context.fetch_object!(ctx, :t, name).id == name

    position1 = Context.fetch_object!(ctx, :t, name).position
    {:ok, ctx0} = Game.start_event(ctx, %Event{name: :move, value: :up, id: name})
    {:ok, ctx1} = Game.invoke_call(slug, :loop)
    position2 = Context.fetch_object!(ctx1, :t, name).position
    assert ctx1.__counters__.loop == ctx0.__counters__.loop + 1
    assert position2 != position1

    {:ok, ctx1} = Game.start_event(ctx1, %Event{name: :toggle_pause, id: name})
    {:paused, _} = Game.start_event(ctx1, %Event{name: :move, value: :up, id: name})

    {:ok, ctx2} = Game.invoke_call(slug, :loop)
    assert ctx1.__counters__.loop + 1 == ctx2.__counters__.loop
    assert ctx2.state == :paused
    assert position2 == Context.fetch_object!(ctx2, :t, name).position
    {:ok, _ctx3} = Game.start_event(ctx2, %Event{name: :toggle_pause, id: name})
    {:ok, ctx3} = Game.invoke_call(slug, :loop)
    assert ctx3.state == :started
    assert ctx3.__counters__.loop == ctx2.__counters__.loop + 1
  end

  test "shoot", %{} do
    slug = "a"
    name = "b"
    {_pid, ctx} = Game.start_server(slug, %{player_name: name, mock: true})
    tank = ctx |> Context.fetch_object!(:tanks, name)
    position = tank.position
    x = position.x
    y = position.y

    assert Map.fetch!(ctx.objects, {x, y}) ==
             %{%Object{type: :t, id: name, enemy?: false} => :up}

    {:ok, ctx} = Game.start_event(ctx, %Event{name: :shoot, id: name})

    assert Map.fetch!(ctx.objects, {x, y}) ==
             %{
               %Object{type: :t, id: name, enemy?: false} => :up,
               %Object{type: :b, id: "b0", enemy?: false} => :up
             }

    assert Enum.count(ctx.bullets) == 1
    bullet = Map.fetch!(ctx.bullets, "b0")
    assert bullet.position.ry == position.ry
    assert position.direction == :up
    {:ok, ctx1} = Game.invoke_call(slug, :loop)
    assert ctx1.__counters__.loop == ctx.__counters__.loop + 1
    new_bullet = Map.fetch!(ctx1.bullets, "b0")
    new_position = new_bullet.position
    assert new_position.ry == position.ry - new_bullet.speed
  end

  # test "kill server", %{} do
  #   bob_pid = GameDynamicSupervisor.server_process("bob")
  # end
end

defmodule BattleCityCoreTest do
  use ExUnit.Case
  doctest BattleCityCore

  test "greets the world" do
    assert BattleCityCore.hello() == :world
  end
end

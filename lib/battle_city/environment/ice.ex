defmodule BattleCity.Environment.Ice do
  @moduledoc false

  use BattleCity.Environment,
    health: 0,
    enter?: false

  @impl true
  def handle_enter(_, %{speed: speed} = t) do
    {:ok, %{t | speed: speed + 10}}
  end

  @impl true
  def handle_leave(_, %{speed: speed} = t) do
    {:ok, %{t | speed: speed - 10}}
  end
end

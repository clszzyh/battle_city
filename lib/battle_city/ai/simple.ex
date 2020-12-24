defmodule BattleCity.Ai.Simple do
  @moduledoc false

  use BattleCity.Ai

  @impl true
  def name, do: "simple"

  @impl true
  def handle_shoot(_, _, _), do: %Event{name: :shoot}

  @impl true
  def handle_move(%Ai{move_event: nil}, _, %Tank{position: %{direction: direction, x: x, y: y}}) do
    %Event{name: :move, value: direction, args: %{x: x, y: y}}
  end

  def handle_move(
        %Ai{move_event: %Event{value: direction, args: %{x: ex, y: ey} = args} = event},
        _,
        %Tank{position: %{direction: direction, x: x, y: y}}
      )
      when {x, y} != {ex, ey} do
    %{event | args: %{args | x: x, y: y}}
  end

  @limit 10
  def handle_move(
        %Ai{move_event: %Event{counter: event_counter}} = ai,
        %Context{__counters__: %{loop: counter}},
        _
      )
      when counter - event_counter < @limit do
    {:same, ai}
  end

  @less_up List.duplicate(:up, 5)

  def handle_move(%Ai{move_event: %Event{value: direction} = event}, _, _) do
    directions =
      @diretions
      |> Kernel.--([direction])
      |> List.duplicate(10)
      |> List.flatten()
      |> Kernel.--(@less_up)

    %{event | value: Enum.random(directions)}
  end
end

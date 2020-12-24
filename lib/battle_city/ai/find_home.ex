defmodule BattleCity.Ai.FindHome do
  @moduledoc false

  use BattleCity.Ai

  @impl true
  def name, do: "find_home"

  @impl true
  def handle_shoot(_, _, %Tank{position: position}) when is_on_border_xy(position), do: nil

  def handle_shoot(_, ctx, %Tank{} = tank) do
    if Ai.has_enemies?(ctx, tank), do: %Event{name: :shoot}
  end

  @impl true
  def handle_move(_, _, _), do: nil
end

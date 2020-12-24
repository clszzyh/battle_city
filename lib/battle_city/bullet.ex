defmodule BattleCity.Bullet do
  @moduledoc """
  Bullet
  """

  alias BattleCity.Callback
  alias BattleCity.Context
  alias BattleCity.Environment
  alias BattleCity.Position

  @type power :: 1..10

  @type t :: %__MODULE__{
          speed: Position.speed(),
          position: Position.t(),
          id: BattleCity.id(),
          __callbacks__: [Callback.t()],
          tank_id: BattleCity.id(),
          reason: BattleCity.reason(),
          power: power,
          enemy?: boolean(),
          hidden?: boolean(),
          dead?: boolean()
        }

  @enforce_keys [:speed, :position, :tank_id, :enemy?]
  defstruct [
    :speed,
    :position,
    :id,
    :reason,
    :tank_id,
    :enemy?,
    power: 1,
    __callbacks__: [],
    hidden?: false,
    dead?: false
  ]

  use BattleCity.Callback

  @impl true
  def handle_callback(%{action: :delete}, %__MODULE__{tank_id: id}, _) do
    fn ctx ->
      ctx
      |> Context.update_object_raw(:tanks, id, fn
        nil -> {nil, nil}
        x -> {x, %{x | shootable?: true}}
      end)
    end
  end

  def handle_callback(
        %{action: :damage_environment, value: %{x: x, y: y, power: power}},
        _,
        %Context{stage: %{map: map_data} = stage} = ctx
      ) do
    {_, data} = Map.get_and_update!(map_data, {x, y}, fn e -> {e, Environment.hit(e, power)} end)
    %{ctx | stage: %{stage | map: data}}
  end

  def handle_callback(_, _, ctx), do: ctx
end

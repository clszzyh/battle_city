defmodule BattleCity.Bullet do
  @moduledoc """
  Bullet
  """

  alias BattleCity.Context
  alias BattleCity.ContextCallback
  alias BattleCity.Environment
  alias BattleCity.Position

  @typep power :: 1..10

  @type t :: %__MODULE__{
          speed: Position.speed(),
          position: Position.t(),
          id: BattleCity.id(),
          __callbacks__: [ContextCallback.t()],
          __module__: module(),
          tank_id: BattleCity.id(),
          reason: BattleCity.reason(),
          power: power,
          enemy?: boolean(),
          hidden?: boolean(),
          reinforced?: boolean(),
          dead?: boolean()
        }

  @enforce_keys [:speed, :position, :tank_id, :enemy?, :__module__, :reinforced?]
  defstruct [
    :speed,
    :position,
    :id,
    :reason,
    :tank_id,
    :enemy?,
    :reinforced?,
    :__module__,
    power: 2,
    __callbacks__: [],
    hidden?: false,
    dead?: false
  ]

  use BattleCity.ContextCallback

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
        %{action: :damage_environment, value: %{x: x, y: y} = value},
        _,
        %Context{stage: %{map: map_data} = stage} = ctx
      ) do
    {_, data} =
      Map.get_and_update!(map_data, {x, y}, fn e ->
        {_state, new_e} = Environment.handle_hit(e, value)
        {e, new_e}
      end)

    %{ctx | stage: %{stage | map: data}}
  end

  def handle_callback(_, _, ctx), do: ctx
end

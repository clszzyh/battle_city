defmodule BattleCity.Event do
  @moduledoc """
  Event
  """

  @typep name :: :shoot | :move | :toggle_pause
  @typep value :: term()

  alias BattleCity.Bullet
  alias BattleCity.Context
  alias BattleCity.Position
  alias BattleCity.Tank
  alias BattleCity.Telemetry

  @type t :: %__MODULE__{
          id: BattleCity.id() | nil,
          counter: integer() | nil,
          name: name(),
          value: value(),
          args: map(),
          ret: atom()
        }

  @enforce_keys [:name]
  defstruct [
    :id,
    :name,
    :value,
    :counter,
    :ret,
    args: %{}
  ]

  @spec handle(Context.t(), t()) :: {atom(), Context.t()}
  def handle(ctx, event) do
    Telemetry.span(
      :game_event,
      fn ->
        {ret, ctx} = handle_1(ctx, event)
        {{ret, ctx}, %{slug: ctx.slug}}
      end,
      %{slug: ctx.slug, event_id: event.id}
    )
  end

  @spec handle_1(Context.t(), t()) :: {atom, Context.t()}
  defp handle_1(%{__events__: events} = ctx, event) do
    {ret, %{__counters__: %{event: event_count} = counter} = ctx} = handle_2(ctx, event)

    ctx =
      if ret in [:ok] do
        ctx
      else
        %{ctx | __events__: [%{event | ret: ret} | events]}
      end

    {ret, %{ctx | __counters__: %{counter | event: event_count + 1}}}
  end

  defp handle_2(%Context{} = ctx, %__MODULE__{name: :move, value: direction, id: id}) do
    ctx = ctx |> Context.update_object_raw!(:tanks, id, &move(&1, direction))
    {:ok, ctx}
  end

  defp handle_2(%Context{} = ctx, %__MODULE__{name: :shoot, id: id}) do
    ctx
    |> Context.fetch_object!(:tanks, id)
    |> shoot
    |> case do
      %Bullet{} = bullet ->
        ctx =
          ctx
          |> Context.update_object_raw!(:tanks, id, fn t -> {t, %{t | shootable?: false}} end)
          |> Context.put_object(bullet)

        {:ok, ctx}

      ret ->
        {ret, ctx}
    end
  end

  defp move(%Tank{position: p} = tank, direction) do
    {tank, %{tank | moving?: true, position: %{p | direction: direction}}}
  end

  @spec shoot(Tank.t()) :: atom() | Bullet.t()
  defp shoot(%Tank{dead?: true}), do: :dead
  defp shoot(%Tank{shootable?: false}), do: :disabled

  defp shoot(%Tank{id: tank_id, enemy?: enemy?, meta: %{bullet_speed: speed}, position: position}) do
    %Bullet{
      enemy?: enemy?,
      position: position,
      tank_id: tank_id,
      speed: speed * Position.bullet_speed()
    }
  end
end

defmodule BattleCity.Business.Generate do
  @moduledoc false

  alias BattleCity.Context
  alias BattleCity.PowerUp
  alias BattleCity.Stage
  alias BattleCity.Tank

  @count 4

  @power_up_modules [
    PowerUp.Grenade,
    PowerUp.Helmet,
    PowerUp.Life,
    PowerUp.Shovel,
    PowerUp.Star,
    PowerUp.Timer
  ]

  @diretions [:up, :down, :left, :right]

  @spec add_power_up(Context.t()) :: Context.t()
  def add_power_up(%Context{rest_enemies: rest_enemies} = ctx)
      when rest_enemies in [4, 8, 12, 16] do
    ctx |> do_add_power_up()
  end

  def add_power_up(%Context{} = ctx) do
    ctx
  end

  @spec do_add_power_up(Context.t(), map()) :: BattleCity.invoke_result()
  def do_add_power_up(%Context{} = ctx, opts \\ %{}) do
    opts = Map.merge(opts, %{x: :x_random, y: :y_random, direction: :down})
    powerup = generate_power_up(opts)
    ctx |> Context.put_object(powerup)
  end

  def generate_power_up(opts) do
    module = @power_up_modules |> Enum.random()
    module.init(opts)
  end

  @spec add_bot(Context.t(), map()) :: Context.t()
  def add_bot(
        %Context{stage: %{bots: bots} = stage, rest_enemies: rest_enemies} = ctx,
        opts \\ %{}
      ) do
    opts =
      Map.merge(opts, %{
        enemy?: true,
        lifes: 1,
        x: Map.get(opts, :enemy_x, :x_random_enemy),
        y: Map.get(opts, :enemy_y, :y_random_enemy),
        direction: Map.get(opts, :enemy_direction, Enum.random(@diretions))
      })

    {tanks, bots} = generate_bots(bots, opts)

    tanks
    |> Enum.reject(&match?(nil, &1))
    |> case do
      [] ->
        ctx

      tanks ->
        %{ctx | rest_enemies: rest_enemies - 1, stage: %{stage | bots: bots}}
        |> Context.put_object(tanks)
    end
  end

  @spec generate_bots(Stage.bots(), map()) :: {[Tank.t()], Stage.bots()}
  defp generate_bots(bots, opts) do
    count = opts[:bot_count] || @count

    Enum.map_reduce(1..count, bots, fn _index, bots ->
      map_reduce_bot(bots, opts)
    end)
  end

  @spec map_reduce_bot(Stage.bots(), map()) :: {Tank.t(), Stage.bots()}
  defp map_reduce_bot(bots, opts) do
    bots
    |> Enum.reject(&match?({_, 0}, &1))
    |> case do
      [] ->
        {nil, bots}

      new_bots ->
        {module, size} = Enum.random(new_bots)
        {module.new(opts), Keyword.put(bots, module, size - 1)}
    end
  end
end

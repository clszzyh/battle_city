defmodule BattleCity do
  @external_resource readme = Path.join([__DIR__, "../README.md"])

  @moduledoc readme |> File.read!() |> String.split("<!-- MDOC -->") |> Enum.fetch!(2)

  # alias BattleCity.Bullet
  alias BattleCity.Context
  alias BattleCity.Tank

  @version Mix.Project.config()[:version]
  def version, do: @version

  @type slug :: binary()
  @type id :: binary() | nil
  @type reason :: atom()
  @type object_keys :: :power_ups | :tanks | :bullets
  @type level :: 1..30

  @type short_type :: :t | :b | :p | :e

  @type invoke_tank_result ::
          {Context.t(), Tank.t()} | Context.t() | Tank.t() | {:error, atom()} | :ignored

  # @type inner_callback_bullet_result ::
  #         {Context.t(), Bullet.t()} | Context.t() | Bullet.t() | {:error, atom()} | :ignored
  # @type callback_bullet_result :: {Context.t(), Bullet.t()}

  @type invoke_result :: {:error, atom()} | Context.t()
end

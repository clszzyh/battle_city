defmodule BattleCity do
  @external_resource readme = Path.join([__DIR__, "../README.md"])

  @moduledoc readme |> File.read!() |> String.split("<!-- MDOC -->") |> Enum.fetch!(2)

  @version Mix.Project.config()[:version]
  def version, do: @version

  @type slug :: binary()
  @type id :: binary() | nil
  @type reason :: atom()
  @type object_keys :: :power_ups | :tanks | :bullets
  @type level :: 1..30

  @type short_type :: :t | :b | :p | :e
end

defmodule BattleCity do
  @external_resource readme = Path.join([__DIR__, "../README.md"])

  @moduledoc readme
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(2)

  @version Mix.Project.config()[:version]
  def version, do: @version
end

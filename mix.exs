defmodule BattleCity.MixProject do
  use Mix.Project

  @version String.trim(File.read!("VERSION"))
  @github_url "https://github.com/clszzyh/battle_city"
  @description String.trim(Enum.at(String.split(File.read!("README.md"), "<!-- MDOC -->"), 1, ""))

  def project do
    [
      app: :battle_city,
      version: @version,
      description: @description,
      elixir: "~> 1.11",
      elixirc_options: [warnings_as_errors: System.get_env("CI") == "true"],
      package: [
        licenses: ["MIT"],
        files: [
          "lib",
          ".formatter.exs",
          "mix.exs",
          "README*",
          "CHANGELOG*",
          "VERSION",
          "priv/stages"
        ],
        exclude_patterns: ["priv/plts", ".DS_Store"],
        links: %{
          "GitHub" => @github_url,
          "Changelog" => @github_url <> "/blob/master/CHANGELOG.md"
        }
      ],
      docs: [
        source_ref: "v" <> @version,
        source_url: @github_url,
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
      ],
      dialyzer: [
        plt_core_path: "priv/plts",
        plt_add_deps: :transitive,
        plt_add_apps: [:ex_unit],
        list_unused_filters: true,
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: dialyzer_flags()
      ],
      preferred_cli_env: [ci: :test],
      start_permanent: Mix.env() == :prod,
      xref: [exclude: :crypto],
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp dialyzer_flags do
    [
      :error_handling,
      :race_conditions,
      # :underspecs,
      :unknown,
      :unmatched_returns
      # :overspecs
      # :specdiffs
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {BattleCity.Application, []},
      env: [telemetry_logger: false],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:telemetry, "~> 0.4.0"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", runtime: false}
    ]
  end

  defp aliases do
    [
      ci: [
        "compile --warnings-as-errors --force --verbose",
        "format --check-formatted",
        "credo --strict",
        "docs",
        "dialyzer",
        "test"
      ]
    ]
  end
end

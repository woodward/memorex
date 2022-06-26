defmodule Memorex.MixProject do
  @moduledoc false
  use Mix.Project

  @source_url "https://github.com/woodward/memorex"
  @version "0.2.0"

  def project do
    [
      app: :memorex,
      dialyzer: [
        plt_add_apps: [:mix],
        plt_add_deps: [:mix]
      ],
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      #
      # Hex
      description: "A spaced-repetition system based on Anki built in Phoenix LiveView which uses Markdown for flashcard content",
      package: package(),
      #
      # Docs
      name: "Memorex",
      docs: docs()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Memorex.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dart_sass, "~> 0.5", runtime: Mix.env() == :dev},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ecto_sql, "~> 3.8"},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.17"},
      {:phoenix, "~> 1.6"},
      {:plug_cowboy, "~> 2.5"},
      {:postgrex, "~> 0.16"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:timex, "~> 3.7"},
      {:toml, "~> 0.6"},
      {:uuid, "~> 1.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "esbuild default --minify",
        "sass default --no-source-map --style=compressed",
        "phx.digest"
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Greg Woodward"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files:
        ~w(.formatter.exs .credo.exs mix.exs README.md lib config assets/js assets/vendor notes) ++
          ~w(assets/css/app.scss assets/css/initial-variables.sass assets/css/derived-variables.sass) ++
          ~w(priv/gettext priv/repo priv/static/assets priv/static/images/caret-down.svg priv/static/images/caret-right.svg ) ++
          ~w(priv/static/favicon.ico priv/static/robots.txt)
    ]
  end

  defp docs() do
    [
      main: "readme",
      source_url: @source_url,
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: groups_for_modules()
    ]
  end

  defp extras() do
    [
      "README.md",
      "notes/Anki Deck Settings.md",
      "notes/Anki notes.md",
      "notes/Anki algorithm for review cards.md",
      "notes/Anki algorithm mental map.md"
    ]
  end

  defp groups_for_extras do
    [
      Notes: ~r/notes\/.?/
    ]
  end

  defp groups_for_modules() do
    [
      Domain: [
        Memorex.Domain.Card,
        Memorex.Domain.Note,
        Memorex.Domain.Deck,
        Memorex.Domain.CardLog
      ],
      Ecto: [
        Memorex.Ecto.Repo,
        Memorex.Ecto.Schema,
        Memorex.Ecto.TimexDuration
      ],
      Scheduler: [
        Memorex.Scheduler.CardStateMachine,
        Memorex.Scheduler.CardReviewer,
        Memorex.Scheduler.Config
      ],
      Contexts: [
        Memorex.Cards,
        Memorex.Decks,
        Memorex.CardLogs
      ],
      MemorexWeb: [
        MemorexWeb,
        MemorexWeb.ErrorHelpers,
        MemorexWeb.ErrorView,
        MemorexWeb.Gettext,
        MemorexWeb.LayoutView,
        MemorexWeb.DecksLive,
        MemorexWeb.ReviewLive,
        MemorexWeb.Router.Helpers,
        MemorexWeb.SharedViewHelpers
      ]
    ]
  end
end

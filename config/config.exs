# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :memorex,
  ecto_repos: [Memorex.Repo]

config :memorex, Memorex.Repo,
  # See `:migration_primary_key` description here: https://hexdocs.pm/ecto_sql/Ecto.Migration.html#module-repo-configuration
  migration_primary_key: [name: :id, type: :binary_id],
  migration_foreign_key: [column: :id, type: :binary_id],
  # See: https://elixirforum.com/t/why-cant-timestamptz-be-set-up-as-default-timestamp-for-migrations-in-config/25778
  # Also: https://elixirguides.com/2019/06/what-is-the-difference-between-utc_datetime-and-naive_datetime-in-ecto/
  migration_timestamps: [type: :timestamptz]

# Configures the endpoint
config :memorex, MemorexWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: MemorexWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Memorex.PubSub,
  live_view: [signing_salt: "EgDTB8ge"]

config :memorex, MemorexWeb.ReviewLive, debug_mode?: true

config :dart_sass,
  version: "1.49.11",
  default: [
    args: ~w(css/app.scss ../priv/static/assets/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

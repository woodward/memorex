import Config

config :memorex,
  ecto_repos: [Memorex.Ecto.Repo]

config :memorex, Memorex.Ecto.Repo,
  # See `:migration_primary_key` description here: https://hexdocs.pm/ecto_sql/Ecto.Migration.html#module-repo-configuration
  migration_primary_key: [name: :id, type: :binary_id],
  migration_foreign_key: [column: :id, type: :binary_id],
  # See: https://elixirforum.com/t/why-cant-timestamptz-be-set-up-as-default-timestamp-for-migrations-in-config/25778
  # Also: https://elixirguides.com/2019/06/what-is-the-difference-between-utc_datetime-and-naive_datetime-in-ecto/
  migration_timestamps: [type: :timestamptz]

config :memorex, MemorexWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: MemorexWeb.ErrorHTML, json: MemorexWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Memorex.PubSub,
  live_view: [signing_salt: "EgDTB8ge"]

config :dart_sass,
  version: "1.54.5",
  # See: https://pragmaticstudio.com/tutorials/using-tailwind-css-in-phoenix
  default: [
    args: ~w(css/app.scss ../priv/static/assets/app.css.tailwind),
    cd: Path.expand("../assets", __DIR__)
  ]

config :esbuild,
  version: "0.17.11",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    # See: https://pragmaticstudio.com/tutorials/using-tailwind-css-in-phoenix
    args: ~w(
      --config=tailwind.config.js
      --input=../priv/static/assets/app.css.tailwind
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"

import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :memorex, Memorex.Ecto.Repo,
  username: "postgres",
  password: "postgres",
  database: "memorex_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :memorex, Memorex.Note,
  bidirectional_note_delimitter: "⮂",
  note_dirs: ["test/fixtures/contains_multiple_decks/dir1", "test/fixtures/contains_multiple_decks/dir2"]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :memorex, MemorexWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "dIEhnYcaalhIo+QHw0MxxRP7Ib8x5DURfqGo5WpebuAeXZb8ZYnLb3VtRV5qqSox",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

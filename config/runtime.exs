import Config

alias Timex.Duration

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# Start the phoenix server if environment is set and running in a  release
if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :memorex, MemorexWeb.Endpoint, server: true
end

defmodule Memorex.Config.Utils do
  @moduledoc false
  def string_array_to_durations(string_array) do
    string_array
    |> String.split(",")
    |> Enum.map(&String.trim(&1))
    |> Enum.map(&Duration.parse!(&1))
  end
end

alias Memorex.Config.Utils

config :memorex, Memorex.Config,
  new_cards_per_day: System.get_env("MEMOREX_NEW_CARDS_PER_DAY", "20") |> String.to_integer(),
  max_reviews_per_day: System.get_env("MEMOREX_MAX_REVIEWS_PER_DAY", "200") |> String.to_integer(),
  #
  learn_ahead_time_interval: System.get_env("MEMOREX_LEARN_AHEAD_TIME_INTERVAL", "PT20M") |> Duration.parse!(),
  #
  learn_steps: System.get_env("MEMOREX_LEARN_STEPS", "PT1M, PT10M") |> Utils.string_array_to_durations(),
  graduating_interval_good: System.get_env("MEMOREX_GRADUATING_INTERVAL_GOOD", "P1D") |> Duration.parse!(),
  graduating_interval_easy: System.get_env("MEMOREX_GRADUATING_INTERVAL_EASY", "P4D") |> Duration.parse!(),
  #
  relearn_steps: System.get_env("MEMOREX_RELEARN_STEPS", "PT10M") |> Duration.parse!(),
  #
  initial_ease: System.get_env("MEMOREX_INITIAL_EASE", "2.5") |> String.to_float(),
  #
  easy_multiplier: System.get_env("MEMOREX_EASY_MULTIPLIER", "1.3") |> String.to_float(),
  hard_multiplier: System.get_env("MEMOREX_HARD_MULTIPLIER", "1.2") |> String.to_float(),
  lapse_multiplier: System.get_env("MEMOREX_LAPSE_MULTIPLIER", "0.0") |> String.to_float(),
  interval_multiplier: System.get_env("MEMOREX_INTERVAL_MULTIPLIER", "1.0") |> String.to_float(),
  #
  ease_again: System.get_env("MEMOREX_EASE_AGAIN", "-0.2") |> String.to_float(),
  ease_hard: System.get_env("MEMOREX_EASE_HARD", "-0.15") |> String.to_float(),
  ease_good: System.get_env("MEMOREX_EASE_GOOD", "0.0") |> String.to_float(),
  ease_easy: System.get_env("MEMOREX_EASE_EASY", "0.15") |> String.to_float()

if config_env() != :test do
  config :memorex, timezone: System.get_env("MEMOREX_TIMEZONE") || raise("environment variable MEMOREX_TIMEZONE is missing")

  note_dirs = System.get_env("MEMOREX_NOTE_DIRS") || raise "Environment variable MEMOREX_NOTE_DIRS must be set!"

  note_dirs = note_dirs |> String.split(",") |> Enum.map(&String.trim(&1))

  bidirectional_note_delimitter =
    System.get_env("MEMOREX_BIDIRECTIONAL_NOTE_DELIMITTER") ||
      raise "Environment variable MEMOREX_BIDIRECTIONAL_NOTE_DELIMITTER must be set!"

  config :memorex, Memorex.Note,
    bidirectional_note_delimitter: bidirectional_note_delimitter,
    note_dirs: note_dirs
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :memorex, Memorex.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :memorex, MemorexWeb.Endpoint,
    url: [host: host, port: 443],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :memorex, MemorexWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.
end

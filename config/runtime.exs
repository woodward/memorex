import Config

alias Timex.Duration

if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :memorex, MemorexWeb.Endpoint, server: true
end

defmodule Memorex.Scheduler.Config.Utils do
  @moduledoc false
  def string_array_to_durations(string_array) do
    string_array
    |> String.split(",")
    |> Enum.map(&String.trim(&1))
    |> Enum.map(&Duration.parse!(&1))
  end
end

alias Memorex.Scheduler.Config.Utils

config :memorex, MemorexWeb.ReviewLive, debug_mode?: System.get_env("MEMOREX_DEBUG_MODE", "false") == "true"

timezone =
  case Timex.Timezone.local() do
    # This case will never actually succeed - perhaps Timex is not up and running at this point?
    %Timex.TimezoneInfo{full_name: tz} -> tz
    #
    # This error case is the one which is actually used; tz is actually the correct value:
    {:error, {:could_not_resolve_timezone, tz, _, :wall}} -> tz
  end

config :memorex, Memorex.Scheduler.Config,
  new_cards_per_day: System.get_env("MEMOREX_NEW_CARDS_PER_DAY", "20") |> String.to_integer(),
  max_reviews_per_day: System.get_env("MEMOREX_MAX_REVIEWS_PER_DAY", "200") |> String.to_integer(),
  #
  learn_ahead_time_interval: System.get_env("MEMOREX_LEARN_AHEAD_TIME_INTERVAL", "PT20M") |> Duration.parse!(),
  #
  learn_steps: System.get_env("MEMOREX_LEARN_STEPS", "PT1M, PT10M") |> Utils.string_array_to_durations(),
  graduating_interval_good: System.get_env("MEMOREX_GRADUATING_INTERVAL_GOOD", "P1D") |> Duration.parse!(),
  graduating_interval_easy: System.get_env("MEMOREX_GRADUATING_INTERVAL_EASY", "P4D") |> Duration.parse!(),
  #
  relearn_steps: System.get_env("MEMOREX_RELEARN_STEPS", "PT10M") |> Utils.string_array_to_durations(),
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
  ease_easy: System.get_env("MEMOREX_EASE_EASY", "0.15") |> String.to_float(),
  ease_minimum: System.get_env("MEMOREX_EASE_MINIMUM", "1.3") |> String.to_float(),
  #
  max_review_interval: System.get_env("MEMOREX_MAX_REVIEW_INTERVAL", "P100Y") |> Duration.parse!(),
  min_review_interval: System.get_env("MEMOREX_MIN_REVIEW_INTERVAL", "P1D") |> Duration.parse!(),
  #
  leech_threshold: System.get_env("MEMOREX_LEECH_THRESHOLD", "8") |> String.to_integer(),
  #
  min_time_to_answer: System.get_env("MEMOREX_MIN_TIME_TO_ANSWER", "PT1S") |> Duration.parse!(),
  max_time_to_answer: System.get_env("MEMOREX_MAX_TIME_TO_ANSWER", "PT1M") |> Duration.parse!(),
  #
  relearn_easy_adj: System.get_env("MEMOREX_RELEARN_EASY_ADJ", "P1D") |> Duration.parse!(),
  #
  timezone: System.get_env("MEMOREX_TIMEZONE", timezone)

if config_env() != :test do
  note_dirs = System.get_env("MEMOREX_NOTE_DIRS") || raise "Environment variable MEMOREX_NOTE_DIRS must be set!"
  note_dirs = note_dirs |> String.split(",") |> Enum.map(&String.trim(&1))

  config :memorex, Memorex.Note,
    bidirectional_note_delimitter: System.get_env("MEMOREX_BIDIRECTIONAL_NOTE_DELIMITTER", "⮂"),
    unidirectional_note_delimitter: System.get_env("MEMOREX_UNIDIRECTIONAL_NOTE_DELIMITTER", "→"),
    note_dirs: note_dirs
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :memorex, Memorex.Ecto.Repo,
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

  config :memorex, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

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

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :memorex, MemorexWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :memorex, MemorexWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end

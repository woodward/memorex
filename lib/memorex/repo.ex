defmodule Memorex.Repo do
  use Ecto.Repo,
    otp_app: :memorex,
    adapter: Ecto.Adapters.Postgres
end

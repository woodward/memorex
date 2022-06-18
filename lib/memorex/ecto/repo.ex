defmodule Memorex.Ecto.Repo do
  @moduledoc """
  An Ecto repo which is used to store the drilling information (e.g., when a card is due, its interval, etc.) and a COPY
  of the `Memorex.Domain.Note` content (which is re-created if the `Memorex.Domain.Deck` Markdown files are re-read
  from the filesystem).
  """
  use Ecto.Repo,
    otp_app: :memorex,
    adapter: Ecto.Adapters.Postgres
end

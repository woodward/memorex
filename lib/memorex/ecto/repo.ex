defmodule Memorex.Ecto.Repo do
  @moduledoc """
  An Ecto repo which is used to store the drilling information (e.g., when a card is due, its interval, etc.) and a COPY
  of the `Memorex.Domain.Note` content (which is refreshed/re-created when the `Memorex.Domain.Deck` Markdown files are
  re-read from the filesystem via the `Mix` task `Mix.Tasks.Memorex.ReadNotes`).
  """
  use Ecto.Repo,
    otp_app: :memorex,
    adapter: Ecto.Adapters.Postgres
end

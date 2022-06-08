defmodule Memorex.CardLogs do
  @moduledoc false

  import Ecto.Query

  alias Memorex.{Repo, Schema}
  alias Memorex.Cards.{Card, CardLog, Deck, Note}

  def count_for_today(deck_id, _time_now, _timezone) do
    deck_id
    |> card_logs_for_deck()
    |> Repo.aggregate(:count, :id)
  end

  @spec card_logs_for_deck(Schema.id(), Keyword.t()) :: Ecto.Query.t()
  def card_logs_for_deck(deck_id, _opts \\ []) do
    from cl in CardLog,
      join: c in Card,
      on: cl.card_id == c.id,
      join: n in Note,
      on: n.id == c.note_id,
      join: d in Deck,
      on: d.id == n.deck_id,
      where: d.id == ^deck_id
  end
end

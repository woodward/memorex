defmodule Memorex.CardLogs do
  @moduledoc false

  import Ecto.Query

  alias Memorex.{Repo, Schema, TimeUtils}
  alias Memorex.Cards.{Card, CardLog, Deck, Note}

  @spec for_day(Ecto.Query.t(), DateTime.t(), String.t()) :: Ecto.Query.t()
  def for_day(query, time_now, timezone) do
    time_now = time_now |> TimeUtils.to_timezone(timezone)
    end_of_day = Timex.end_of_day(time_now) |> TimeUtils.to_timezone("Etc/UTC")
    start_of_day = Timex.beginning_of_day(time_now) |> TimeUtils.to_timezone("Etc/UTC")

    query
    |> where([cl], ^start_of_day <= cl.inserted_at and cl.inserted_at <= ^end_of_day)
  end

  @spec all() :: Ecto.Query.t()
  def all(), do: from(cl in CardLog)

  @spec count(Ecto.Query.t()) :: non_neg_integer()
  def count(query), do: query |> Repo.aggregate(:count, :id)

  @spec count_for_deck_for_today(Schema.id(), DateTime.t(), String.t()) :: non_neg_integer()
  def count_for_deck_for_today(deck_id, time_now, timezone) do
    all() |> for_deck(deck_id) |> for_day(time_now, timezone) |> count()
  end

  @spec for_deck(Ecto.Query.t(), Schema.id(), Keyword.t()) :: Ecto.Query.t()
  def for_deck(_query, deck_id, _opts \\ []) do
    # query
    # |> where([cl],
    #   join: c in Card,
    #   on: cl.card_id == c.id,
    #   join: n in Note,
    #   on: n.id == c.note_id,
    #   join: d in Deck,
    #   on: d.id == n.deck_id,
    #   where: d.id == ^deck_id
    # )

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

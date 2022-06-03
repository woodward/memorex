defmodule Memorex.Cards do
  @moduledoc false

  import Ecto.Query

  alias Memorex.Cards.{Card, Deck, Note}
  alias Memorex.{Config, Repo}

  @spec update_card!(Card.t(), map(), DateTime.t()) :: Card.t()
  def update_card!(card, changes, time) do
    card
    |> Card.changeset(changes)
    |> Card.set_due_field_in_changeset(time)
    |> Card.increment_reps()
    |> Repo.update!()
  end

  @spec update_new_cards_to_learn_cards(Ecto.Queryable.t(), Config.t(), DateTime.t(), Keyword.t()) :: :ok
  def update_new_cards_to_learn_cards(queryable, config, time_now, opts \\ []) do
    first_learn_step = config.learn_steps |> List.first()

    updates = [
      card_queue: :learn,
      card_type: :learn,
      due: Timex.shift(time_now, duration: first_learn_step),
      interval: first_learn_step,
      lapses: 0,
      remaining_steps: length(config.learn_steps),
      reps: 0
    ]

    Repo.update_all(queryable, [set: updates], opts)
  end

  @spec cards_for_deck(Ecto.UUID.t(), Keyword.t()) :: Ecto.Query.t()
  def cards_for_deck(deck_id, opts \\ []) do
    query =
      from c in Card,
        join: n in Note,
        on: n.id == c.note_id,
        join: d in Deck,
        on: d.id == n.deck_id,
        where: d.id == ^deck_id

    # There _has_ to be a way to merge in the opts in a general way - find it!!!
    limit = Keyword.get(opts, :limit)
    if limit, do: from(c in query, limit: ^limit), else: query

    # Card
    # |> join(:inner, [c], n in Note, on: c.note_id == n.id)
    # |> join(:inner, [c, n], d in Deck, on: n.deck_id == d.id)
    # |> where([c, n, d], d.id == ^deck_id)
  end

  @spec set_new_cards_in_deck_to_learn_cards(Ecto.UUID.t(), Config.t(), DateTime.t(), Keyword.t()) :: :ok
  def set_new_cards_in_deck_to_learn_cards(deck_id, config, time_now, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    deck_id
    |> cards_for_deck(limit: limit)
    |> Repo.all()
    |> Enum.each(fn card ->
      card
      |> Card.learn_card_to_new_card_changeset(config, time_now)
      |> Repo.update!()
    end)
  end
end

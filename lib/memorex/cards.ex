defmodule Memorex.Cards do
  @moduledoc false

  import Ecto.Query

  alias Memorex.Domain.{Card, CardLog, Deck, Note}
  alias Memorex.Scheduler.{CardStateMachine, Config}
  alias Memorex.Ecto.{Repo, Schema}
  alias Timex.Duration

  @spec update_card!(Card.t(), map(), DateTime.t()) :: Card.t()
  def update_card!(card, changes, time) do
    card
    |> Card.changeset(changes)
    |> Card.set_due_field_in_changeset(time)
    |> Card.increment_reps()
    |> Repo.update!()
  end

  @spec get_card!(Schema.id()) :: Card.t()
  def get_card!(card_id) do
    Repo.get!(Card, card_id) |> Repo.preload([:card_logs, :note])
  end

  @spec cards_for_deck(Schema.id(), Keyword.t()) :: Ecto.Query.t()
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

  @spec create_bidirectional_from_note(Note.t()) :: Schema.id()
  def(create_bidirectional_from_note(note)) do
    card1 = %Card{note: note, note_question_index: 0, note_answer_index: 1}
    card2 = %Card{note: note, note_question_index: 1, note_answer_index: 0}
    Repo.insert!(card1)
    Repo.insert!(card2)
  end

  @spec set_new_cards_in_deck_to_learn_cards(Schema.id(), Config.t(), DateTime.t(), Keyword.t()) :: :ok
  def set_new_cards_in_deck_to_learn_cards(deck_id, config, time_now, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    deck_id
    |> cards_for_deck(limit: limit)
    |> where_card_type(:new)
    # The following RANDOM line is untested (but without it cards are definitely NOT random):
    |> order_by(fragment("RANDOM()"))
    |> Repo.all()
    |> Enum.each(&convert_new_card_to_learn_card(&1, config, time_now))
  end

  @spec convert_new_card_to_learn_card(Card.t(), Config.t(), DateTime.t()) :: Card.t()
  def convert_new_card_to_learn_card(card_before, config, time_now) do
    updates = CardStateMachine.convert_new_card_to_learn_card(card_before, config, time_now)
    card_after = card_before |> Card.changeset(updates) |> Repo.update!()
    CardLog.new(nil, card_before, card_after, nil) |> Repo.insert!()
    card_after
  end

  @spec where_due(Ecto.Query.t(), DateTime.t()) :: Ecto.Query.t()
  def where_due(query, time_now) do
    query
    |> where([c], c.due <= ^time_now)
  end

  @spec where_card_type(Ecto.Query.t(), Card.card_type()) :: Ecto.Query.t()
  def where_card_type(query, card_type) do
    query
    |> where([c], c.card_type == ^card_type)
  end

  @spec get_one_random_due_card(Schema.id(), DateTime.t()) :: Card.t() | nil
  def get_one_random_due_card(deck_id, time_now) do
    cards_for_deck(deck_id, limit: 1)
    |> where_due(time_now)
    |> order_by(fragment("RANDOM()"))
    |> preload(:note)
    |> Repo.one()
  end

  @spec count(Schema.id()) :: non_neg_integer()
  def count(deck_id) do
    deck_id
    |> cards_for_deck()
    |> Repo.aggregate(:count, :id)
  end

  @spec count(Schema.id(), Card.card_type()) :: non_neg_integer()
  def count(deck_id, card_type) do
    deck_id
    |> cards_for_deck()
    |> where(card_type: ^card_type)
    |> Repo.aggregate(:count, :id)
  end

  @spec due_count(Schema.id(), DateTime.t()) :: non_neg_integer()
  def due_count(deck_id, time_now) do
    deck_id
    |> cards_for_deck()
    |> where_due(time_now)
    |> Repo.aggregate(:count, :id)
  end

  @spec get_interval_choices(Card.t(), Config.t(), DateTime.t()) :: [{Card.answer_choice(), Duration.t()}]
  def get_interval_choices(card, config, time_now) do
    Card.answer_choices()
    |> Enum.map(fn answer ->
      changes = CardStateMachine.answer_card(card, answer, config, time_now)
      interval = card |> Card.changeset(changes) |> Ecto.Changeset.get_field(:interval)
      {answer, interval}
    end)
  end
end

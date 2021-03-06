defmodule Memorex.Cards do
  @moduledoc """
  Functions for interacting with `Memorex.Domain.Card`s.
  """

  import Ecto.Query

  alias Memorex.Domain.{Card, CardLog, Deck, Note}
  alias Memorex.Scheduler.{CardStateMachine, Config}
  alias Memorex.Ecto.{Repo, Schema}
  alias Timex.Duration

  @doc "Updates a card, and in the process sets the `:due` field, and also increments the rep count"
  @spec update_card_when_reviewing!(Card.t(), map(), DateTime.t()) :: Card.t()
  def update_card_when_reviewing!(card, changes, time) do
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

  @spec update(Card.t(), map()) :: {:ok, Card.t()} | {:error, Ecto.Changeset.t()}
  def update(card, card_params) do
    card |> Card.changeset(card_params) |> Repo.update()
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

  # @spec create_from_note(Note.t()) :: Note.t()
  @spec create_from_note(Note.t()) :: Ecto.Schema.t()
  def(create_from_note(note)) do
    card1 =
      if note.image_file_path do
        %Card{note: note, note_question_index: nil, note_answer_index: 0}
      else
        %Card{note: note, note_question_index: 0, note_answer_index: 1}
      end

    Repo.insert!(card1)

    if note.bidirectional? do
      card2 = %Card{note: note, note_question_index: 1, note_answer_index: 0}
      Repo.insert!(card2)
    end
  end

  @spec set_new_cards_in_deck_to_learn_cards(Schema.id(), Config.t(), DateTime.t(), Keyword.t()) :: :ok
  def set_new_cards_in_deck_to_learn_cards(deck_id, config, time_now, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    deck_id
    |> cards_for_deck(limit: limit)
    |> where(card_type: :new)
    # The following RANDOM line is untested (but without it cards are definitely NOT random):
    |> order_by(fragment("RANDOM()"))
    |> Repo.all()
    |> Enum.each(&convert_new_card_to_learn_card(&1, config, time_now))
  end

  @doc """
  Converts a `Memorex.Domain.Card` from a `:new` card to a `:learn` card (and in the process creates a
  `Memorex.Domain.CardLog` entry).
  """
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

  @spec get_one_random_due_card(Schema.id(), DateTime.t()) :: Card.t() | nil
  def get_one_random_due_card(deck_id, time_now) do
    cards_for_deck(deck_id, limit: 1)
    |> where_due(time_now)
    |> where(card_status: :active)
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

  @spec count(Schema.id(), Keyword.t()) :: non_neg_integer()
  def count(deck_id, opts) do
    card_type = Keyword.get(opts, :card_type)
    card_status = Keyword.get(opts, :card_status)

    query = deck_id |> cards_for_deck()
    query = if card_type, do: query |> where(card_type: ^card_type), else: query
    query = if card_status, do: query |> where(card_status: ^card_status), else: query

    query |> Repo.aggregate(:count, :id)
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

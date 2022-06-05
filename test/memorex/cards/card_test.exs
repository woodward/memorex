defmodule Memorex.Cards.CardTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{Config, Repo}
  alias Memorex.Cards.{Card, CardLog, Note}
  alias Timex.Duration

  test "deletes card logs when deleted" do
    card = Repo.insert!(%Card{})

    card_log =
      Repo.insert!(%CardLog{
        card: card,
        ease_factor: 2.5,
        interval: Duration.parse!("PT1S"),
        last_interval: Duration.parse!("PT1S"),
        time_to_answer: Timex.Duration.parse!("PT1S")
      })

    Repo.delete!(card)
    assert Repo.get(CardLog, card_log.id) == nil
  end

  test "can create cards from a note" do
    note = Note.new(content: ["one", "two"]) |> Repo.insert!()
    Card.create_bidirectional_from_note(note)

    assert Repo.all(Card) |> length() == 2

    [card1, card2] = Repo.all(Card, order_by: :note_answer_index)

    assert card1.note_question_index == 0
    assert card1.note_answer_index == 1
    assert card1.note_id == note.id

    assert card2.note_question_index == 1
    assert card2.note_answer_index == 0
    assert card2.note_id == note.id
  end

  test "enums work properly" do
    card = Repo.insert!(%Card{card_type: :relearn, card_queue: :review})
    assert card.card_type == :relearn
    assert card.card_queue == :review
  end

  test "default values" do
    card = %Card{}
    assert card.card_queue == :new
    assert card.card_type == :new
  end

  test "changeset" do
    card = %Card{
      card_queue: :day_learn,
      card_type: :relearn,
      ease_factor: 2.5,
      interval: Duration.parse!("PT33S"),
      lapses: 2,
      remaining_steps: 7
    }

    card_changeset =
      Card.changeset(card, %{
        card_queue: :learn,
        card_type: :review,
        due: ~U[2022-05-30 15:44:00Z],
        ease_factor: 2.4,
        interval: Duration.parse!("PT47S"),
        lapses: 3,
        note_answer_index: 3,
        note_question_index: 4,
        remaining_steps: 2,
        reps: 36
      })

    changes = card_changeset.changes

    assert changes.card_queue == :learn
    assert changes.card_type == :review
    assert changes.due == ~U[2022-05-30 15:44:00Z]
    assert changes.ease_factor == 2.4
    assert changes.interval == Duration.parse!("PT47S")
    assert changes.lapses == 3
    assert changes.note_answer_index == 3
    assert changes.note_question_index == 4
    assert changes.remaining_steps == 2
    assert changes.reps == 36
  end

  describe "set_due_field_in_changeset" do
    test "sets the due field based on a time plus the current interval contained in the changeset" do
      card = %Card{interval: Duration.parse!("PT33S")}
      changeset = Card.changeset(card, %{interval: Duration.parse!("P1D")})
      now = ~U[2022-05-30 15:44:00Z]
      changeset = Card.set_due_field_in_changeset(changeset, now)
      changes = changeset.changes

      assert changes.interval == Duration.parse!("P1D")
      assert changes.due == ~U[2022-05-31 15:44:00Z]
    end

    test "sets the due field based on a time plus the current interval contained in the card" do
      card = %Card{interval: Duration.parse!("P1D")}
      changeset = Card.changeset(card, %{})
      now = ~U[2022-05-30 15:44:00Z]
      changeset = Card.set_due_field_in_changeset(changeset, now)
      changes = changeset.changes

      assert changes.due == ~U[2022-05-31 15:44:00Z]
    end
  end

  describe "increment_reps" do
    test "increments the reps value" do
      card = %Card{reps: 3}
      changeset = Card.changeset(card, %{})
      changeset = Card.increment_reps(changeset)
      assert changeset.changes.reps == 4
    end
  end

  describe "learn_card_to_new_card_changeset/3" do
    test "sets the values based on the config" do
      config = %Config{
        learn_steps: [Duration.parse!("PT2M"), Duration.parse!("PT15M")],
        initial_ease: 2.25
      }

      card = %Card{card_type: :new, ease_factor: 2.15, lapses: 2, reps: 33, card_queue: :review}

      time_now = ~U[2022-02-01 12:00:00Z]
      changeset = Card.learn_card_to_new_card_changeset(card, config, time_now)

      changes = changeset.changes

      assert changes.remaining_steps == 2
      assert changes.card_type == :learn
      assert changes.card_queue == :learn
      assert changes.lapses == 0
      assert changes.reps == 0
      assert changes.due == time_now
      assert changes.interval == Duration.parse!("PT0S")
    end
  end

  describe "question/1" do
    test "returns the question from the note" do
      note = %Note{content: ["First", "Second"]}
      card1 = %Card{note: note, note_question_index: 0}
      assert Card.question(card1) == "First"

      card2 = %Card{note: note, note_question_index: 1}
      assert Card.question(card2) == "Second"
    end
  end

  describe "answer/1" do
    test "returns the answer from the note" do
      note = %Note{content: ["First", "Second"]}
      card1 = %Card{note: note, note_answer_index: 0}
      assert Card.answer(card1) == "First"

      card2 = %Card{note: note, note_answer_index: 1}
      assert Card.answer(card2) == "Second"
    end
  end
end

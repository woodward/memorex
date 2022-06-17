defmodule Memorex.Domain.CardTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Ecto.Repo
  alias Memorex.Domain.{Card, CardLog, Deck, Note}
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

  test "enums work properly" do
    card = Repo.insert!(%Card{card_type: :relearn})
    assert card.card_type == :relearn
  end

  test "default values" do
    card = %Card{}
    assert card.card_type == :new
  end

  describe "changeset" do
    test "changeset" do
      card = %Card{
        card_status: :active,
        card_type: :relearn,
        ease_factor: 2.5,
        interval: Duration.parse!("PT33S"),
        lapses: 2,
        current_step: 7
      }

      card_changeset =
        Card.changeset(card, %{
          "card_queue" => :learn,
          "card_status" => :suspended,
          "card_type" => :review,
          "due" => ~U[2022-05-30 15:44:00Z],
          "ease_factor" => 2.4,
          "interval" => Duration.parse!("PT47S"),
          "interval_prior_to_lapse" => Duration.parse!("P100D"),
          "lapses" => 3,
          "note_answer_index" => 3,
          "note_question_index" => 4,
          "current_step" => 2,
          "reps" => 36
        })

      changes = card_changeset.changes

      assert changes.card_status == :suspended
      assert changes.card_type == :review
      assert changes.due == ~U[2022-05-30 15:44:00Z]
      assert changes.ease_factor == 2.4
      assert changes.interval == Duration.parse!("PT47S")
      assert changes.interval_prior_to_lapse == Duration.parse!("P100D")
      assert changes.lapses == 3
      assert changes.note_answer_index == 3
      assert changes.note_question_index == 4
      assert changes.current_step == 2
      assert changes.reps == 36
    end

    test "converts an interval string to a Timex.Duration" do
      card = %Card{interval: Duration.parse!("PT1M"), interval_prior_to_lapse: Duration.parse!("PT2M")}

      card_changeset = Card.changeset(card, %{"interval" => "PT10M", "interval_prior_to_lapse" => "PT20M"})

      changes = card_changeset.changes
      assert changes.interval == Duration.parse!("PT10M")
      assert changes.interval_prior_to_lapse == Duration.parse!("PT20M")
    end

    test "shows an error if unable to convert interval strings to Timex.Duration" do
      card = %Card{interval: Duration.parse!("PT1M"), interval_prior_to_lapse: Duration.parse!("PT2M")}

      changeset = Card.changeset(card, %{"interval" => "invalid-duration", "interval_prior_to_lapse" => "another-invalid-duration"})

      assert changeset.valid? == false

      assert "invalid duration" in errors_on(changeset).interval
      assert "invalid duration" in errors_on(changeset).interval_prior_to_lapse
    end
  end

  describe "set_due_field_in_changeset" do
    test "sets the due field based on a time plus the current interval contained in the changeset" do
      card = %Card{interval: Duration.parse!("PT33S")}
      changeset = Card.changeset(card, %{"interval" => Duration.parse!("P1D")})
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

  describe "deck" do
    test "can get the deck through the note" do
      deck = %Deck{name: "foobar"} |> Repo.insert!()
      note = %Note{deck: deck} |> Repo.insert!()
      card = %Card{note: note} |> Repo.insert!() |> Repo.preload([:note, :deck])

      assert card.deck.name == "foobar"
    end
  end
end

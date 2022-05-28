defmodule Memorex.Cards.CardTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Repo
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

  describe "bracket_time_to_answer/1" do
    test "returns the actual time to answer if it is not too large or too small" do
      time_to_answer = Timex.Duration.parse!("PT15S")
      assert Card.bracket_time_to_answer(time_to_answer) == Timex.Duration.parse!("PT15S")
    end

    test "returns the minimum time if the time to answer is too small" do
      time_to_answer = Timex.Duration.parse!("PT0S")
      assert Card.bracket_time_to_answer(time_to_answer) == Timex.Duration.parse!("PT1S")
    end

    test "returns the maximum time if the time to answer is too large" do
      time_to_answer = Timex.Duration.parse!("PT61S")
      assert Card.bracket_time_to_answer(time_to_answer) == Timex.Duration.parse!("PT1M")
    end
  end
end

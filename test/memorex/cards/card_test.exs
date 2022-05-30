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

  test "changeset" do
    card = %Card{
      card_queue: :day_learn,
      card_type: :relearn,
      interval: Duration.parse!("PT33S"),
      ease_factor: 2.5
    }

    card_changeset = Card.changeset(card, %{card_queue: :learn, card_type: :review, interval: Duration.parse!("PT47S"), ease_factor: 2.4})

    changes = card_changeset.changes

    assert changes.ease_factor == 2.4
    assert changes.card_queue == :learn
    assert changes.card_type == :review
    assert changes.interval == Duration.parse!("PT47S")
  end
end

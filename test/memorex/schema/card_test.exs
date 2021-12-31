defmodule Memorex.Schema.CardTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Schema.{Card, CardLog, Note}
  alias Memorex.Repo

  test "deletes card logs when deleted" do
    card = Repo.insert!(%Card{})
    card_log = Repo.insert!(%CardLog{card: card})

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
end

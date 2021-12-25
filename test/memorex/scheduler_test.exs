defmodule Memorex.SchedulerTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{Card, Deck, Note, Repo, Scheduler}

  describe "get_cards_for_drilling" do
    test "returns the cards for drilling" do
      deck1 = Repo.insert!(%Deck{name: "deck1"})
      deck2 = Repo.insert!(%Deck{name: "deck2"})

      note1 = Repo.insert!(Note.new(content: ["question1", "answer1"], deck: deck1))
      note2 = Repo.insert!(Note.new(content: ["question2", "answer2"], deck: deck2))

      card1_1 = Repo.insert!(%Card{note: note1, note_question_index: 0, note_answer_index: 1})
      card1_2 = Repo.insert!(%Card{note: note1, note_question_index: 1, note_answer_index: 0})
      card2_1 = Repo.insert!(%Card{note: note2, note_question_index: 0, note_answer_index: 1})
      card2_2 = Repo.insert!(%Card{note: note2, note_question_index: 1, note_answer_index: 0})

      decks = [deck1, deck2]

      cards = Scheduler.get_cards_for_drilling(decks)
      card_ids = cards |> Enum.map(& &1.id) |> Enum.sort()
      expected_card_ids = [card1_1.id, card1_2.id, card2_1.id, card2_2.id] |> Enum.sort()
      assert card_ids == expected_card_ids
    end
  end
end

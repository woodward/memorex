defmodule Memorex.DeckTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{Card, CardLog, Deck, Note}

  test "deletes notes, cards, and card logs when deleted" do
    deck = Repo.insert!(%Deck{})
    note = Repo.insert!(%Note{deck: deck})
    card = Repo.insert!(%Card{note: note})
    card_log = Repo.insert!(%CardLog{card: card})

    Repo.delete!(deck)

    assert Repo.get(Note, note.id) == nil
    assert Repo.get(Card, card.id) == nil
    assert Repo.get(CardLog, card_log.id) == nil
  end

  test "a deck has many cards through a note" do
    deck = Repo.insert!(%Deck{})
    note = Repo.insert!(%Note{deck: deck})
    card = Repo.insert!(%Card{note: note})

    deck = Repo.get(Deck, deck.id) |> Repo.preload(:cards)
    [card_from_deck] = deck.cards
    assert card_from_deck.id == card.id
  end

  describe "read" do
    test "a file gets converted into notes" do
      Deck.read_file("test/fixtures/deck1.md")

      deck = Repo.all(Deck) |> Repo.preload(:notes) |> Repo.preload(:cards) |> List.first()

      assert deck.name == "deck1"
      assert deck.notes |> length() == 3
      assert deck.cards |> length() == 6
    end
  end
end

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

  describe "read_file" do
    test "a file gets converted into notes" do
      Deck.read_file("test/fixtures/deck1.md")

      assert Repo.all(Note) |> length() == 3
      assert Repo.all(Card) |> length() == 6
    end

    test "can take an optional deck" do
      deck = Repo.insert!(%Deck{name: "My Deck"})
      Deck.read_file("test/fixtures/deck1.md", deck)

      deck = Repo.all(Deck) |> Repo.preload(:notes) |> Repo.preload(:cards) |> List.first()

      assert deck.name == "My Deck"
      assert deck.notes |> length() == 3
      assert deck.cards |> length() == 6
    end
  end

  describe "read_dir" do
    test "all of the files in a directory get incorporated into the deck" do
      Deck.read_dir("test/fixtures/deck")

      deck = Repo.all(Deck) |> List.first()
      assert deck.name == "deck"

      [note1, note2] = Repo.all(Note, order_by: :id) |> Repo.preload(:deck)
      assert note1.deck.name == "deck"
      assert note2.deck.name == "deck"

      assert Repo.all(Card) |> length() == 4
    end
  end
end

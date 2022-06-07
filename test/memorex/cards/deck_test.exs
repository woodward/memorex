defmodule Memorex.Cards.DeckTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Cards.{Card, CardLog, Deck, Note}
  alias Timex.Duration

  test "deletes notes, cards, and card logs when deleted" do
    deck = Repo.insert!(%Deck{})
    note = Repo.insert!(%Note{deck: deck})
    card = Repo.insert!(%Card{note: note})

    card_log =
      Repo.insert!(%CardLog{
        card: card,
        ease_factor: 2.5,
        interval: Duration.parse!("PT1S"),
        last_interval: Duration.parse!("PT1S"),
        time_to_answer: Timex.Duration.parse!("PT1S")
      })

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

  describe "config" do
    test "the config is stored in the database as JSONB (i.e., as a map)" do
      config = %{new_cards_per_day: 20}
      deck = %Deck{config: config} |> Repo.insert!()

      retrieved_deck = Repo.get!(Deck, deck.id)

      assert retrieved_deck.config["new_cards_per_day"] == 20
    end
  end
end

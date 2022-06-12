defmodule Memorex.DecksTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Decks
  alias Memorex.Domain.Deck

  describe "find_or_create!" do
    test "creates a deck if one does not exist with this name" do
      deck = Decks.find_or_create!("deck-1")
      assert deck.name == "deck-1"
    end

    test "returns the deck if one already exists with this name" do
      Repo.insert!(%Deck{name: "deck-1"})
      assert Repo.all(Deck) |> length() == 1

      deck = Decks.find_or_create!("deck-1")
      assert deck.name == "deck-1"
      assert Repo.all(Deck) |> length() == 1
    end
  end

  describe "update_config" do
    test "updates the config file in the deck" do
      deck = %Deck{config: %{"new_cards_per_day" => 12}} |> Repo.insert!()
      deck = Decks.update_config(deck, %{"new_cards_per_day" => 34})
      assert deck.config == %{"new_cards_per_day" => 34}
    end
  end
end

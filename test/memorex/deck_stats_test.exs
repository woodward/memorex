defmodule Memorex.DeckStatsTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.DeckStats
  alias Memorex.Ecto.Repo
  alias Memorex.Domain.{Card, Deck, Note}

  describe "new/2" do
    test "returns the stats for the deck" do
      time_now = ~U[2022-02-01 12:00:00Z]
      due = ~U[2022-02-01 11:59:00Z]
      not_due = ~U[2022-02-01 12:01:00Z]

      deck1 = Repo.insert!(%Deck{})
      note1 = Repo.insert!(%Note{deck: deck1})
      note2 = Repo.insert!(%Note{deck: deck1})
      _card1 = Repo.insert!(%Card{note: note1, due: due, card_type: :learn, card_status: :active})
      _card2 = Repo.insert!(%Card{note: note1, due: not_due, card_type: :review, card_status: :suspended})
      _card3 = Repo.insert!(%Card{note: note2, due: not_due, card_type: :new, card_status: :active})
      _card4 = Repo.insert!(%Card{note: note2, due: due, card_type: :new, card_status: :active})

      deck2 = Repo.insert!(%Deck{})
      note1_deck2 = Repo.insert!(%Note{deck: deck2})
      _deck2_card1 = Repo.insert!(%Card{note: note1_deck2, due: due, card_status: :active})

      deck_stats = DeckStats.new(deck1.id, time_now)

      assert deck_stats.total == 4
      assert deck_stats.new == 2
      assert deck_stats.learn == 1
      assert deck_stats.review == 1
      assert deck_stats.due == 2
      assert deck_stats.suspended == 1
    end
  end
end

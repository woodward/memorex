defmodule Memorex.CardsTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{Cards, Config, Repo}
  alias Memorex.Cards.Card
  alias Timex.Duration

  describe "update_card!" do
    test "updates the card and also the due field, and incrementes the reps field" do
      old_due = ~U[2022-01-01 12:00:00Z]
      card = %Card{due: old_due, interval: Duration.parse!("P1D"), reps: 3}
      card = Repo.insert!(card)
      time_now = ~U[2022-02-01 12:00:00Z]

      updated_card = Cards.update_card!(card, %{interval: Duration.parse!("P10D")}, time_now)

      assert updated_card.due == ~U[2022-02-11 12:00:00Z]
      assert updated_card.interval == Duration.parse!("P10D")
      assert updated_card.reps == 4
    end
  end

  describe "update_new_cards_to_learn_cards/3" do
    test "sets the values based on the config" do
      config = %Config{
        learn_steps: [Duration.parse!("PT2M"), Duration.parse!("PT15M")],
        initial_ease: 2.25
      }

      card1 = %Card{card_type: :new, ease_factor: 2.15, lapses: 2, reps: 33, card_queue: :review} |> Repo.insert!()

      time_now = ~U[2022-02-01 12:00:00Z]
      Cards.update_new_cards_to_learn_cards(Card, config, time_now)

      card1 = Repo.get!(Card, card1.id)

      assert card1.interval == Duration.parse!("PT2M")
      assert card1.remaining_steps == 2
      assert card1.card_type == :learn
      assert card1.card_queue == :learn
      assert card1.lapses == 0
      assert card1.reps == 0
      assert card1.due == ~U[2022-02-01 12:02:00Z]
    end
  end
end

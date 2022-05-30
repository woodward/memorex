defmodule Memorex.CardReviewerTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{Cards, CardReviewer, Config}
  alias Memorex.Cards.Card
  alias Timex.Duration

  describe "bracket_time_to_answer/1" do
    setup do
      config = %Config{min_time_to_answer: Duration.parse!("PT1S"), max_time_to_answer: Duration.parse!("PT1M")}
      [config: config]
    end

    test "returns the actual time to answer if it is not too large or too small", %{config: config} do
      time_to_answer = Duration.parse!("PT15S")
      assert CardReviewer.bracket_time_to_answer(time_to_answer, config) == Duration.parse!("PT15S")
    end

    test "returns the minimum time if the time to answer is too small", %{config: config} do
      time_to_answer = Duration.parse!("PT0S")
      assert CardReviewer.bracket_time_to_answer(time_to_answer, config) == Duration.parse!("PT1S")
    end

    test "returns the maximum time if the time to answer is too large", %{config: config} do
      time_to_answer = Duration.parse!("PT61S")
      assert CardReviewer.bracket_time_to_answer(time_to_answer, config) == Duration.parse!("PT1M")
    end
  end

  describe "time_to_answer/1" do
    setup do
      config = %Config{min_time_to_answer: Duration.parse!("PT1S"), max_time_to_answer: Duration.parse!("PT1M")}
      [config: config]
    end

    test "returns the actual time to answer if it is not too large or too small", %{config: config} do
      start_time = ~U[2022-01-01 12:00:00Z]
      end_time = ~U[2022-01-01 12:00:30Z]
      assert CardReviewer.time_to_answer(start_time, end_time, config) == Duration.parse!("PT30S")
    end

    test "returns the minimum time if the time to answer is too small", %{config: config} do
      start_time = ~U[2022-01-01 12:00:00Z]
      end_time = ~U[2022-01-01 12:00:00Z]
      assert CardReviewer.time_to_answer(start_time, end_time, config) == Duration.parse!("PT1S")
    end

    test "returns the maximum time if the time to answer is too large", %{config: config} do
      start_time = ~U[2022-01-01 12:00:00Z]
      end_time = ~U[2022-01-01 12:02:30Z]
      assert CardReviewer.time_to_answer(start_time, end_time, config) == Duration.parse!("PT1M")
    end
  end

  describe "answer_card" do
    test "answers the card" do
      config = %Config{
        learn_steps: [Duration.parse!("PT2M"), Duration.parse!("PT15M")],
        initial_ease: 2.4
      }

      card = Repo.insert!(%Card{card_type: :new})

      time_now = ~U[2022-01-02 12:00:00Z]
      Cards.update_new_cards_to_learn_cards(Card, config, time_now)
      card = Repo.get!(Card, card.id)

      card = CardReviewer.answer_card(card, :again, time_now, config)

      assert card.card_type == :learn
      assert card.card_queue == :learn
      assert card.remaining_steps == 2
      assert card.due == ~U[2022-01-02 12:02:00Z]
      assert card.interval == Duration.parse!("PT2M")
      assert card.ease_factor == 2.4
      assert card.remaining_steps == 2
      # assert card1.reps == 0
    end
  end
end

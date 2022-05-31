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

  describe "answer_card_and_create_log_entry" do
    test "answers the card, and creates a log entry" do
      card = %Card{card_type: :review, interval: Duration.parse!("PT4M"), ease_factor: 2.5, reps: 3}
      card = Repo.insert!(card)
      config = %Config{interval_multiplier: 1.0, ease_good: 0.0}
      start_time = ~U[2022-01-01 12:02:00Z]
      time_now = ~U[2022-01-01 12:04:00Z]

      card_log = CardReviewer.answer_card_and_create_log_entry(card, :good, start_time, time_now, config)

      assert card_log.answer_choice == :good
      assert card_log.card_id == card.id
      assert card_log.card_type == :review
      assert card_log.ease_factor == 2.5
      assert card_log.interval == Duration.parse!("PT10M")
      assert card_log.last_interval == Duration.parse!("PT4M")
      assert card_log.time_to_answer == Duration.parse!("PT60S")

      card = Repo.get!(Card, card.id)

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-01 12:14:00Z]
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("PT10M")
      assert card.remaining_steps == nil
      assert card.reps == 4
    end
  end

  describe "answer_card - old" do
    test "answers the card" do
      config = %Config{
        learn_steps: [Duration.parse!("PT2M"), Duration.parse!("PT15M"), Duration.parse!("PT30M")],
        initial_ease: 2.4,
        graduating_interval_good: Duration.parse!("P2D")
      }

      card = Repo.insert!(%Card{card_type: :new})

      time_now = ~U[2022-01-01 12:00:00Z]
      Cards.update_new_cards_to_learn_cards(Card, config, time_now)
      card = Repo.get!(Card, card.id)
      # ------- Learn cards --------------------------------------------------------------------------------------------

      # -------- Initial :learn card
      assert card.card_type == :learn
      assert card.card_queue == :learn
      assert card.remaining_steps == 3
      assert card.interval == Duration.parse!("PT2M")
      assert card.due == ~U[2022-01-01 12:02:00Z]
      assert card.ease_factor == nil
      assert card.reps == 0

      # -------- Answer :again - don't advance any steps
      card = CardReviewer.answer_card(card, :again, time_now, config)

      assert card.card_type == :learn
      assert card.card_queue == :learn
      assert card.remaining_steps == 3
      assert card.interval == Duration.parse!("PT2M")
      assert card.due == ~U[2022-01-01 12:02:00Z]
      assert card.ease_factor == nil
      assert card.reps == 1

      # -------- Answer :good - advance one step
      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:01:00Z], config)

      assert card.card_type == :learn
      assert card.card_queue == :learn
      assert card.remaining_steps == 2
      assert card.interval == Duration.parse!("PT15M")
      assert card.due == ~U[2022-01-01 12:16:00Z]
      assert card.ease_factor == nil
      assert card.reps == 2

      # -------- Answer :good - advance one step
      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:16:00Z], config)

      assert card.card_type == :learn
      assert card.card_queue == :learn
      assert card.remaining_steps == 1
      assert card.interval == Duration.parse!("PT30M")
      assert card.due == ~U[2022-01-01 12:46:00Z]
      assert card.ease_factor == nil
      assert card.reps == 3

      # -------- Answer :good - become a review card
      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:46:00Z], config)

      # ------- Review cards -------------------------------------------------------------------------------------------

      assert card.card_type == :review
      # assert card.card_queue == :review
      assert card.remaining_steps == 0
      assert card.interval == Duration.parse!("P2D")
      assert card.due == ~U[2022-01-03 12:46:00Z]
      assert card.ease_factor == 2.4
      assert card.reps == 4
      old_interval = card.interval
      old_ease_factor = card.ease_factor

      # -------- Answer :hard
      config = %{config | hard_multiplier: 1.2, interval_multiplier: 1.1, ease_hard: -0.15}
      card = CardReviewer.answer_card(card, :hard, ~U[2022-01-03 12:00:00Z], config)

      assert card.card_type == :review
      # assert card.card_queue == :learn
      assert card.remaining_steps == 0
      expected_interval = Duration.scale(old_interval, 1.2 * 1.1 * old_ease_factor)
      assert card.interval == expected_interval
      assert card.due == ~U[2022-01-09 20:03:50Z]
      assert card.ease_factor == 2.25
      assert card.reps == 5
      old_interval = card.interval
      old_ease_factor = card.ease_factor

      # -------- Answer :good
      config = %{config | interval_multiplier: 1.2}
      card = CardReviewer.answer_card(card, :good, ~U[2022-01-09 12:00:00Z], config)

      assert card.card_type == :review
      # assert card.card_queue == :learn
      assert card.remaining_steps == 0
      expected_interval = Duration.scale(old_interval, 1.2 * old_ease_factor)
      assert card.interval == expected_interval
      assert card.due == ~U[2022-01-26 14:34:22Z]
      assert card.ease_factor == old_ease_factor
      assert card.reps == 6
      old_interval = Duration.parse!("P1D")
      old_ease_factor = 2.2
      card = card |> Card.changeset(%{interval: old_interval, ease_factor: old_ease_factor}) |> Repo.update!()

      # -------- Answer :easy
      config = %{config | interval_multiplier: 1.0, easy_multiplier: 1.3, ease_easy: 0.15}
      card = CardReviewer.answer_card(card, :easy, ~U[2022-01-09 12:00:00Z], config)

      assert card.card_type == :review
      # assert card.card_queue == :learn
      assert card.remaining_steps == 0
      expected_interval = Duration.scale(old_interval, 1.0 * 1.3 * old_ease_factor)
      assert card.interval == expected_interval
      assert card.due == ~U[2022-01-12 08:38:24Z]
      assert card.ease_factor == old_ease_factor + 0.15
      assert card.reps == 7

      # -------- Answer :again

      config = %{config | ease_again: -0.3, interval_multiplier: 1.0, relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")]}
      card = CardReviewer.answer_card(card, :again, ~U[2022-01-09 12:00:00Z], config)

      assert card.card_type == :relearn
      # assert card.card_queue == :learn
      assert card.remaining_steps == 2
      assert card.interval == Duration.parse!("PT0S")
      assert card.due == ~U[2022-01-09 12:00:00Z]
      assert_in_delta(card.ease_factor, 2.05, 0.00001)
      assert card.reps == 8
      assert card.lapses == 1
    end
  end

  describe "answer_card/4" do
    # ======================== Learn Cards =============================================================================
    # ======================== Review Cards ============================================================================
    # ======================== Relearn Cards ===========================================================================
    test "relearn card - answer :again" do
    end

    test "relearn card - answer :hard" do
      config = %Config{relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")]}

      card =
        %Card{
          # card_queue: :review,
          card_type: :relearn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("PT10M"),
          lapses: 0,
          remaining_steps: 1,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :hard, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :relearn
      assert card.due == ~U[2022-01-01 12:10:00Z]
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("PT10M")
      assert card.lapses == 0
      assert card.remaining_steps == 1
      assert card.reps == 4
    end

    test "relearn card - answer :good - one remaining step" do
      config = %Config{relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")]}

      card =
        %Card{
          # card_queue: :review,
          card_type: :relearn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("PT10M"),
          lapses: 0,
          remaining_steps: 1,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-02 12:00:00Z]
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("P1D")
      assert card.lapses == 0
      assert card.remaining_steps == 0
      assert card.reps == 4
    end
  end
end

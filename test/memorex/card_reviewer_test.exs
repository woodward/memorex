defmodule Memorex.CardReviewerTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{CardReviewer, Config}
  alias Memorex.Cards.{Card, Note}
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
      note = %Note{content: ["First", "Second"]}
      card = %Card{card_type: :review, interval: Duration.parse!("PT4M"), ease_factor: 2.5, reps: 3, note: note}
      card = Repo.insert!(card)
      config = %Config{interval_multiplier: 1.0, ease_good: 0.0, max_time_to_answer: Duration.parse!("PT1M")}
      start_time = ~U[2022-01-01 12:02:00Z]
      time_now = ~U[2022-01-01 12:04:00Z]

      {card, card_log} = CardReviewer.answer_card_and_create_log_entry(card, :good, start_time, time_now, config)

      assert card_log.answer_choice == :good
      assert card_log.card_id == card.id
      assert card_log.card_type == :review
      assert card_log.ease_factor == 2.5
      assert card_log.interval == Duration.parse!("PT10M")
      assert card_log.last_interval == Duration.parse!("PT4M")
      assert card_log.time_to_answer == Duration.parse!("PT60S")

      # Verify preload works:
      assert card_log.card.ease_factor == 2.5
      assert card_log.note.content == ["First", "Second"]

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-01 12:14:00Z]
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("PT10M")
      assert card.remaining_steps == nil
      assert card.reps == 4
    end
  end

  describe "answer_card/4" do
    # ======================== Learn Cards =============================================================================
    test "learn card - answer :again" do
      config = %Config{learn_steps: [Duration.parse!("PT2M"), Duration.parse!("PT15M")]}

      card =
        %Card{
          # card_queue: :review,
          card_type: :learn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: nil,
          interval: Duration.parse!("PT1M"),
          lapses: 0,
          remaining_steps: 2,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :again, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :learn
      assert card.due == ~U[2022-01-01 12:01:00Z]
      assert card.ease_factor == nil
      assert card.interval == Duration.parse!("PT1M")
      assert card.lapses == 0
      assert card.remaining_steps == 2
      assert card.reps == 4
    end

    test "learn card - answer :hard" do
      config = %Config{learn_steps: [Duration.parse!("PT2M"), Duration.parse!("PT15M")]}

      card =
        %Card{
          # card_queue: :review,
          card_type: :learn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: nil,
          interval: Duration.parse!("PT1M"),
          lapses: 0,
          remaining_steps: 2,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :hard, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :learn
      assert card.due == ~U[2022-01-01 12:01:00Z]
      assert card.ease_factor == nil
      assert card.interval == Duration.parse!("PT1M")
      assert card.lapses == 0
      assert card.remaining_steps == 2
      assert card.reps == 4
    end

    test "learn card - answer :good - advance one step" do
      config = %Config{learn_steps: [Duration.parse!("PT2M"), Duration.parse!("PT15M")]}

      card =
        %Card{
          # card_queue: :review,
          card_type: :learn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: nil,
          interval: Duration.parse!("PT1M"),
          lapses: 0,
          remaining_steps: 2,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :learn
      assert card.due == ~U[2022-01-01 12:15:00Z]
      assert card.ease_factor == nil
      assert card.interval == Duration.parse!("PT15M")
      assert card.lapses == 0
      assert card.remaining_steps == 1
      assert card.reps == 4
    end

    test "learn card - answer :good - become a review card" do
      config = %Config{initial_ease: 2.5, graduating_interval_good: Duration.parse!("P1D")}

      card =
        %Card{
          # card_queue: :review,
          card_type: :learn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: nil,
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

    # ======================== Review Cards ============================================================================
    test "review card - answer :again" do
      config = %Config{ease_again: -0.2, relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")], lapse_multiplier: 0.0}

      card =
        %Card{
          # card_queue: :review,
          card_type: :review,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("PT10M"),
          lapses: 0,
          remaining_steps: 1,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :again, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :relearn
      assert card.due == ~U[2022-01-01 12:00:00Z]
      assert card.ease_factor == 2.3
      assert card.interval == Duration.parse!("PT0S")
      assert card.lapses == 1
      assert card.remaining_steps == 2
      assert card.reps == 4
    end

    test "review card - answer :hard" do
      config = %Config{interval_multiplier: 1.1, ease_hard: -0.15, hard_multiplier: 1.2}

      card =
        %Card{
          # card_queue: :review,
          card_type: :review,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("P1D"),
          lapses: 0,
          remaining_steps: 0,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :hard, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-04 19:12:00Z]
      assert card.ease_factor == 2.35
      assert card.interval == Duration.parse!("P3DT7H12M")
      assert card.lapses == 0
      assert card.remaining_steps == 0
      assert card.reps == 4
    end

    test "review card - answer :good" do
      config = %Config{interval_multiplier: 1.1, ease_good: 0.1}

      card =
        %Card{
          # card_queue: :review,
          card_type: :review,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("P1D"),
          lapses: 0,
          remaining_steps: 0,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-04 06:00:00Z]
      assert card.ease_factor == 2.6
      assert card.interval == Duration.parse!("P2DT18H")
      assert card.lapses == 0
      assert card.remaining_steps == 0
      assert card.reps == 4
    end

    test "review card - answer :easy" do
      config = %Config{interval_multiplier: 1.1, easy_multiplier: 1.3, ease_easy: 0.15}

      card =
        %Card{
          # card_queue: :review,
          card_type: :review,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("P1D"),
          lapses: 0,
          remaining_steps: 0,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :easy, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-05 01:48:00Z]
      assert card.ease_factor == 2.65
      assert card.interval == Duration.parse!("P3DT13H48M")
      assert card.lapses == 0
      assert card.remaining_steps == 0
      assert card.reps == 4
    end

    # ======================== Relearn Cards ===========================================================================
    test "relearn card - answer :again" do
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

      card = CardReviewer.answer_card(card, :again, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :relearn
      assert card.due == ~U[2022-01-01 12:10:00Z]
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("PT10M")
      assert card.lapses == 0
      assert card.remaining_steps == 2
      assert card.reps == 4
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
      config = %Config{relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")], min_review_interval: Duration.parse!("P1D")}

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

    test "relearn card - answer :easy - become a review card again" do
      config = %Config{relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")], min_review_interval: Duration.parse!("P1D")}

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

      card = CardReviewer.answer_card(card, :easy, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-03 12:00:00Z]
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("P2D")
      assert card.lapses == 0
      assert card.remaining_steps == 0
      assert card.reps == 4
    end
  end
end

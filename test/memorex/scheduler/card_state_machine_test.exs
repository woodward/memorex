defmodule Memorex.Scheduler.CardStateMachineTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Domain.Card
  alias Memorex.Scheduler.{CardStateMachine, Config}
  alias Timex.Duration

  # ======================== New Cards =================================================================================
  describe "convert_new_card_to_learn_card/3" do
    test "sets the values based on the config" do
      config = %Config{
        learn_steps: [Duration.parse!("PT2M"), Duration.parse!("PT15M")],
        initial_ease: 2.25
      }

      card = %Card{card_type: :new, ease_factor: 2.15, lapses: 2, reps: 33, card_queue: :review}

      time_now = ~U[2022-02-01 12:00:00Z]
      changes = CardStateMachine.convert_new_card_to_learn_card(card, config, time_now)

      assert changes.current_step == 0
      assert changes.card_type == :learn
      assert changes.card_queue == :learn
      assert changes.lapses == 0
      assert changes.reps == 0
      assert changes.due == time_now
      assert changes.interval == Duration.parse!("PT2M")
    end
  end

  # ======================== Learn Cards ===============================================================================
  describe "learn cards" do
    test "answer: 'again'" do
      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")]}
      card = %Card{card_type: :learn, current_step: 1}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :again, config, unused_time_now)

      assert changes == %{current_step: 0}
    end

    test "answer: 'hard'" do
      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")]}
      card = %Card{card_type: :learn, current_step: 1}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :hard, config, unused_time_now)

      assert changes == %{}
    end

    test "answer: 'good' and this is the last learning step" do
      config = %Config{
        learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")],
        graduating_interval_good: Duration.parse!("P1D"),
        initial_ease: 2.34
      }

      card = %Card{card_type: :learn, current_step: 1}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :good, config, unused_time_now)

      assert changes == %{card_type: :review, current_step: nil, interval: Duration.parse!("P1D"), ease_factor: 2.34}
    end

    test "answer: 'good' but this is not the last learning step - 2 remaining steps" do
      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")]}
      card = %Card{card_type: :learn, current_step: 0}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :good, config, unused_time_now)

      assert changes == %{current_step: 1, interval: Duration.parse!("PT10M")}
    end

    test "answer: 'easy'" do
      config = %Config{initial_ease: 2.34, graduating_interval_easy: Duration.parse!("P4D")}
      card = %Card{card_type: :learn}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :easy, config, unused_time_now)

      assert changes == %{card_type: :review, ease_factor: 2.34, interval: Duration.parse!("P4D")}
    end
  end

  # ======================== Review Cards ==============================================================================
  describe "review cards" do
    test "answer: 'again'" do
      config = %Config{
        lapse_multiplier: 0.5,
        ease_again: -0.3,
        relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT1H")],
        min_review_interval: Duration.parse!("P1D")
      }

      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P4D"), current_step: 3, lapses: 3}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :again, config, unused_time_now)

      assert changes == %{
               ease_factor: 2.2,
               card_type: :relearn,
               current_step: 0,
               interval: Duration.parse!("P1D"),
               lapses: 4,
               interval_prior_to_lapse: Duration.parse!("P4D")
             }
    end

    test "answer: 'hard'" do
      # Based on:
      # https://github.com/ankitects/anki/blob/fbb0d909354b53e602151206dab442e92969b3a8/pylib/tests/test_schedv2.py#L381
      config = %Config{interval_multiplier: 1.0, hard_multiplier: 1.2, ease_hard: -0.15, max_review_interval: Duration.parse!("P100Y")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P100D")}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :hard, config, unused_time_now)
      assert changes == %{ease_factor: 2.35, interval: Duration.parse!("P120D")}
    end

    test "answer: 'hard' - interval_multiplier that's not 1.0" do
      config = %Config{interval_multiplier: 1.1, hard_multiplier: 1.2, ease_hard: -0.15, max_review_interval: Duration.parse!("P100Y")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P100D")}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :hard, config, unused_time_now)
      assert changes == %{ease_factor: 2.35, interval: Duration.parse!("P4M12D")}
    end

    test "answer: 'hard' - interval is capped by max interval" do
      config = %Config{interval_multiplier: 1.0, hard_multiplier: 1.2, ease_hard: -0.15, max_review_interval: Duration.parse!("P5D")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P100D")}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :hard, config, unused_time_now)
      assert changes == %{ease_factor: 2.35, interval: Duration.parse!("P5D")}
    end

    test "answer: 'good'" do
      # Based on:
      # https://github.com/ankitects/anki/blob/fbb0d909354b53e602151206dab442e92969b3a8/pylib/tests/test_schedv2.py#L396
      config = %Config{ease_good: 0.1, interval_multiplier: 1.0, max_review_interval: Duration.parse!("P100Y")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P100D"), due: ~U[2021-12-24 12:00:00Z]}
      time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :good, config, time_now)
      assert changes == %{ease_factor: 2.6, interval: Duration.parse!("P260D")}
    end

    test "answer: 'good' - interval_multiplier that's not 1.0" do
      config = %Config{ease_good: 0.1, interval_multiplier: 1.1, max_review_interval: Duration.parse!("P100Y")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P100D"), due: ~U[2021-12-24 12:00:00Z]}
      time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :good, config, time_now)
      assert changes == %{ease_factor: 2.6, interval: Duration.parse!("P9M16D")}
    end

    test "answer: 'good' - interval is capped by max interval" do
      config = %Config{ease_good: 0.1, interval_multiplier: 1.0, max_review_interval: Duration.parse!("P5D")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P100D"), due: ~U[2021-12-24 12:00:00Z]}
      time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :good, config, time_now)
      assert changes == %{ease_factor: 2.6, interval: Duration.parse!("P5D")}
    end

    test "answer: 'good' - bug fix - time_now is BEFORE due" do
      config = %Config{ease_good: 0.1, interval_multiplier: 1.0, max_review_interval: Duration.parse!("P100Y")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P100D"), due: ~U[2022-01-01 12:00:00Z]}
      time_now = ~U[2021-12-24 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :good, config, time_now)
      assert changes == %{ease_factor: 2.6, interval: Duration.parse!("P8M10D")}
    end

    test "answer: 'easy'" do
      # Based on:
      # https://github.com/ankitects/anki/blob/fbb0d909354b53e602151206dab442e92969b3a8/pylib/tests/test_schedv2.py#L406
      config = %Config{interval_multiplier: 1.0, easy_multiplier: 1.3, ease_easy: 0.15, max_review_interval: Duration.parse!("P100Y")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P100D"), due: ~U[2021-12-24 12:00:00Z]}
      time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :easy, config, time_now)
      assert changes == %{ease_factor: 2.65, interval: Duration.parse!("P351D")}
    end

    test "answer: 'easy' - interval_multiplier that's not 1.0" do
      config = %Config{interval_multiplier: 1.1, easy_multiplier: 1.3, ease_easy: 0.15, max_review_interval: Duration.parse!("P100Y")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P100D"), due: ~U[2021-12-24 12:00:00Z]}
      time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :easy, config, time_now)
      assert changes == %{ease_factor: 2.65, interval: Duration.parse!("P1Y21DT2H24M")}
    end

    test "answer: 'easy' - interval is capped by max interval" do
      config = %Config{interval_multiplier: 1.0, easy_multiplier: 1.3, ease_easy: 0.15, max_review_interval: Duration.parse!("P5D")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P100D"), due: ~U[2021-12-24 12:00:00Z]}
      time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :easy, config, time_now)
      assert changes == %{ease_factor: 2.65, interval: Duration.parse!("P5D")}
    end

    test "answer: 'easy' - bug fix - time_now is BEFORE due date/time" do
      config = %Config{interval_multiplier: 1.0, easy_multiplier: 1.3, ease_easy: 0.15, max_review_interval: Duration.parse!("P100Y")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P100D"), due: ~U[2022-01-01 12:00:00Z]}
      time_now = ~U[2021-12-24 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :easy, config, time_now)
      assert changes == %{ease_factor: 2.65, interval: Duration.parse!("P10M25D")}
    end
  end

  # ======================== Relearn Cards =============================================================================
  describe "relearn cards" do
    test "answer: 'again'" do
      config = %Config{relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT1H")]}
      card = %Card{card_type: :relearn, current_step: 1}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :again, config, unused_time_now)

      assert changes == %{current_step: 0}
    end

    test "answer: 'hard'" do
      config = %Config{}
      card = %Card{card_type: :relearn}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :hard, config, unused_time_now)

      assert changes == %{}
    end

    test "answer: 'good' - no more remaining steps" do
      config = %Config{min_review_interval: Duration.parse!("P3D"), relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")]}
      card = %Card{card_type: :relearn, current_step: 1}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :good, config, unused_time_now)

      assert changes == %{card_type: :review, interval: Duration.parse!("P3D"), current_step: nil, interval_prior_to_lapse: nil}
    end

    test "answer: 'good' - there are remaining steps" do
      config = %Config{relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")]}
      card = %Card{card_type: :relearn, current_step: 0}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :good, config, unused_time_now)

      assert changes == %{current_step: 1, interval: Duration.parse!("PT20M")}
    end

    test "answer: 'easy'" do
      config = %Config{min_review_interval: Duration.parse!("P3D"), relearn_easy_adj: Duration.parse!("P2D")}
      card = %Card{card_type: :relearn, current_step: 1}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :easy, config, unused_time_now)

      assert changes == %{card_type: :review, interval: Duration.parse!("P5D"), current_step: nil, interval_prior_to_lapse: nil}
    end
  end

  # ======================== Utilities =================================================================================

  describe "cap_duration" do
    setup do
      one_month = Duration.parse!("P1M")
      [max: one_month]
    end

    test "returns the duration if it's less than the max", %{max: one_month} do
      fifteen_days = Duration.parse!("P15D")
      assert CardStateMachine.cap_duration(fifteen_days, one_month) == fifteen_days
    end

    test "caps the duration at the max if it's more than the max", %{max: one_month} do
      forty_five_days = Duration.parse!("P45D")
      assert CardStateMachine.cap_duration(forty_five_days, one_month) == one_month
    end

    test "returns the duration if it's equal to the max", %{max: one_month} do
      one_month_2 = Duration.parse!("P1M")
      assert CardStateMachine.cap_duration(one_month_2, one_month) == one_month
    end
  end
end

defmodule Memorex.CardStateMachineTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Cards.Card
  alias Memorex.{CardStateMachine, Config}
  alias Timex.Duration

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
      config = %Config{lapse_multiplier: 0.5, ease_again: -0.3, relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT1H")]}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P4D"), current_step: 3, lapses: 3}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :again, config, unused_time_now)

      assert changes == %{ease_factor: 2.2, card_type: :relearn, current_step: 0, interval: Duration.parse!("P2D"), lapses: 4}
    end

    test "answer: 'hard'" do
      config = %Config{interval_multiplier: 1.1, hard_multiplier: 1.25, ease_hard: -0.25, max_review_interval: Duration.parse!("P100Y")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P4D")}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :hard, config, unused_time_now)
      scale = 1.1 * 1.25
      new_interval = Duration.parse!("P4D") |> Timex.Duration.scale(scale)

      assert changes == %{ease_factor: 2.25, interval: new_interval}
    end

    test "answer: 'hard' - interval stays below max interval" do
      config = %Config{interval_multiplier: 1.1, hard_multiplier: 1.25, ease_hard: -0.25, max_review_interval: Duration.parse!("P5D")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P4D")}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :hard, config, unused_time_now)

      assert changes == %{ease_factor: 2.25, interval: Duration.parse!("P5D")}
    end

    test "answer: 'good'" do
      config = %Config{interval_multiplier: 1.1, ease_good: 0.1, max_review_interval: Duration.parse!("P100Y")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P4D")}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :good, config, unused_time_now)
      scale = 2.5 * 1.1
      new_interval = Duration.parse!("P4D") |> Timex.Duration.scale(scale)

      assert changes == %{ease_factor: 2.6, interval: new_interval}
    end

    test "answer: 'good' - interval stays below max interval" do
      config = %Config{interval_multiplier: 1.1, ease_good: 0.1, max_review_interval: Duration.parse!("P5D")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P4D")}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :good, config, unused_time_now)

      assert changes == %{ease_factor: 2.6, interval: Duration.parse!("P5D")}
    end

    test "answer: 'easy'" do
      config = %Config{interval_multiplier: 1.1, easy_multiplier: 1.3, ease_easy: 0.2, max_review_interval: Duration.parse!("P100Y")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P4D")}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :easy, config, unused_time_now)
      scale = 2.5 * 1.1 * 1.3
      new_interval = Duration.parse!("P4D") |> Timex.Duration.scale(scale)

      assert changes == %{ease_factor: 2.7, interval: new_interval}
    end

    test "answer: 'easy' - interval stays below max_interval" do
      config = %Config{interval_multiplier: 1.1, easy_multiplier: 1.3, ease_easy: 0.2, max_review_interval: Duration.parse!("P1M")}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P15D")}
      unused_time_now = ~U[2022-01-01 12:00:00Z]

      changes = CardStateMachine.answer_card(card, :easy, config, unused_time_now)

      assert changes == %{ease_factor: 2.7, interval: Duration.parse!("P1M")}
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

      assert changes == %{card_type: :review, interval: Duration.parse!("P3D"), current_step: nil}
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

      assert changes == %{card_type: :review, interval: Duration.parse!("P5D"), current_step: nil}
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

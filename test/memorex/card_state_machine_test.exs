defmodule Memorex.CardStateMachineTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Cards.Card
  alias Memorex.{CardStateMachine, Config}
  alias Timex.Duration

  describe "learn cards" do
    test "answer: 'again'" do
      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")]}
      card = %Card{card_type: :learn, remaining_steps: 1}

      changes = CardStateMachine.answer_card(card, :again, config)

      assert changes == %{remaining_steps: 2}
    end

    test "answer: 'hard'" do
      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")]}
      card = %Card{card_type: :learn, remaining_steps: 1}

      changes = CardStateMachine.answer_card(card, :hard, config)

      assert changes == %{}
    end

    test "answer: 'good' but this is not the last learning step" do
      config = %Config{
        learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")],
        graduating_interval_good: Duration.parse!("P1D"),
        initial_ease: 2.34
      }

      card = %Card{card_type: :learn, remaining_steps: 1}

      changes = CardStateMachine.answer_card(card, :good, config)

      assert changes == %{card_type: :review, remaining_steps: 0, interval: Duration.parse!("P1D"), ease_factor: 2.34}
    end

    test "answer: 'good' but this is not the last learning step - 2 remaining steps" do
      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")]}
      card = %Card{card_type: :learn, remaining_steps: 2}

      changes = CardStateMachine.answer_card(card, :good, config)

      assert changes == %{remaining_steps: 1, interval: Duration.parse!("PT10M")}
    end

    test "answer: 'easy'" do
      config = %Config{initial_ease: 2.34, graduating_interval_easy: Duration.parse!("P4D")}
      card = %Card{card_type: :learn}

      changes = CardStateMachine.answer_card(card, :easy, config)

      assert changes == %{card_type: :review, ease_factor: 2.34, interval: Duration.parse!("P4D")}
    end
  end

  describe "review cards" do
    test "answer: 'again'" do
      config = %Config{lapse_multiplier: 0.5, ease_again: -0.3, relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT1H")]}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P4D"), remaining_steps: 3, lapses: 3}

      changes = CardStateMachine.answer_card(card, :again, config)

      assert changes == %{ease_factor: 2.2, card_type: :relearn, remaining_steps: 2, interval: Duration.parse!("P2D"), lapses: 4}
    end

    test "answer: 'hard'" do
      config = %Config{interval_multiplier: 1.1, hard_multiplier: 1.25, ease_hard: -0.25}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P4D")}

      changes = CardStateMachine.answer_card(card, :hard, config)
      scale = 2.5 * 1.1 * 1.25
      new_interval = Duration.parse!("P4D") |> Timex.Duration.scale(scale)

      assert changes == %{ease_factor: 2.25, interval: new_interval}
    end

    test "answer: 'good'" do
      config = %Config{interval_multiplier: 1.1, ease_good: 0.1}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P4D")}

      changes = CardStateMachine.answer_card(card, :good, config)
      scale = 2.5 * 1.1
      new_interval = Duration.parse!("P4D") |> Timex.Duration.scale(scale)

      assert changes == %{ease_factor: 2.6, interval: new_interval}
    end

    test "answer: 'easy'" do
      config = %Config{interval_multiplier: 1.1, easy_multiplier: 1.3, ease_easy: 0.2}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P4D")}

      changes = CardStateMachine.answer_card(card, :easy, config)
      scale = 2.5 * 1.1 * 1.3
      new_interval = Duration.parse!("P4D") |> Timex.Duration.scale(scale)

      assert changes == %{ease_factor: 2.7, interval: new_interval}
    end
  end

  describe "relearn cards" do
    test "answer: 'again'" do
      config = %Config{relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT1H")]}
      card = %Card{card_type: :relearn, remaining_steps: 1}

      changes = CardStateMachine.answer_card(card, :again, config)

      assert changes == %{remaining_steps: 2}
    end

    test "answer: 'hard'" do
      config = %Config{}
      card = %Card{card_type: :relearn}

      changes = CardStateMachine.answer_card(card, :hard, config)

      assert changes == %{}
    end

    test "answer: 'good' - no more remaining steps" do
      config = %Config{min_review_interval: Duration.parse!("P3D")}
      card = %Card{card_type: :relearn, remaining_steps: 0}

      changes = CardStateMachine.answer_card(card, :good, config)

      assert changes == %{card_type: :review, interval: Duration.parse!("P3D")}
    end

    test "answer: 'good' - there are remaining steps" do
      config = %Config{}
      card = %Card{card_type: :relearn, remaining_steps: 1}

      changes = CardStateMachine.answer_card(card, :good, config)

      assert changes == %{remaining_steps: 0}
    end

    test "answer: 'easy'" do
      config = %Config{min_review_interval: Duration.parse!("P3D"), relearn_easy_adj: Duration.parse!("P2D")}
      card = %Card{card_type: :relearn, remaining_steps: 1}

      changes = CardStateMachine.answer_card(card, :easy, config)

      assert changes == %{card_type: :review, interval: Duration.parse!("P5D")}
    end
  end
end

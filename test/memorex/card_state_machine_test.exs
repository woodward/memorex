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

    test "answer: 'good' and this is the last learning step" do
      config = %Config{initial_ease: 2.34, graduating_interval_good: Duration.parse!("P1D")}
      card = %Card{card_type: :learn, remaining_steps: 0}

      changes = CardStateMachine.answer_card(card, :good, config)

      assert changes == %{card_type: :review, ease_factor: 2.34, interval: Duration.parse!("P1D")}
    end

    test "answer: 'good' but this is not the last learning step" do
      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")]}
      card = %Card{card_type: :learn, remaining_steps: 1}

      changes = CardStateMachine.answer_card(card, :good, config)

      assert changes == %{remaining_steps: 0}
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
      config = %Config{}
      card = %Card{card_type: :review, ease_factor: 2.5, interval: Duration.parse!("P4D"), remaining_steps: 3}

      changes = CardStateMachine.answer_card(card, :again, config)

      assert changes == %{ease_factor: 2.3, card_type: :relearn, remaining_steps: 0}
    end
  end

  describe "relearn cards" do
  end
end

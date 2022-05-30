defmodule Memorex.CardStateMachineTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Cards.Card
  alias Memorex.{CardStateMachine, Config}
  alias Timex.Duration

  describe "learn cards" do
    test "answer: 'easy'" do
      config = %Config{}
      card = Card.new(config)
      card = %{card | card_type: :learn}

      changes = CardStateMachine.answer_card(card, :easy, config)

      assert changes == %{card_type: :review}
    end

    test "answer: 'good' and this is the last learning step" do
      config = %Config{}
      card = Card.new(config)
      card = %{card | card_type: :learn, remaining_steps: 0}

      changes = CardStateMachine.answer_card(card, :good, config)

      assert changes == %{card_type: :review}
    end

    test "answer: 'good' but this is not the last learning step" do
      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")]}
      card = Card.new(config)
      card = %{card | card_type: :learn, remaining_steps: 1}

      changes = CardStateMachine.answer_card(card, :good, config)

      assert changes == %{remaining_steps: 0}
    end

    test "answer: 'hard'" do
      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")]}
      card = Card.new(config)
      card = %{card | card_type: :learn, remaining_steps: 1}

      changes = CardStateMachine.answer_card(card, :hard, config)

      assert changes == %{}
    end

    test "answer: 'again'" do
      config = %Config{learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")]}
      card = Card.new(config)
      card = %{card | card_type: :learn, remaining_steps: 1}

      changes = CardStateMachine.answer_card(card, :again, config)

      assert changes == %{remaining_steps: 2}
    end
  end
end

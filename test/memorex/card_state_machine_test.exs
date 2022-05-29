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
      card = %{card | card_type: :learn}

      changes = CardStateMachine.answer_card(card, :good, config)

      assert changes == %{card_type: :review}
    end

    test "answer: 'good' but this is not the last learning step" do
      config = %Config{}
      card = Card.new(config)
      card = %{card | card_type: :learn}

      changes = CardStateMachine.answer_card(card, :good, config)

      assert changes == %{card_type: :review}
    end
  end

  describe "bracket_time_to_answer/1" do
    test "returns the actual time to answer if it is not too large or too small" do
      time_to_answer = Duration.parse!("PT15S")
      assert CardStateMachine.bracket_time_to_answer(time_to_answer) == Duration.parse!("PT15S")
    end

    test "returns the minimum time if the time to answer is too small" do
      time_to_answer = Duration.parse!("PT0S")
      assert CardStateMachine.bracket_time_to_answer(time_to_answer) == Duration.parse!("PT1S")
    end

    test "returns the maximum time if the time to answer is too large" do
      time_to_answer = Duration.parse!("PT61S")
      assert CardStateMachine.bracket_time_to_answer(time_to_answer) == Duration.parse!("PT1M")
    end
  end
end

defmodule Memorex.CardStateMachineTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Cards.Card
  alias Memorex.{CardStateMachine, Config}
  alias Timex.Duration

  describe "new cards" do
    test "graduates to the next learning step" do
      config = %Config{max_time_to_answer: Duration.parse!("PT2M")}
      card = Card.new(config)
      assert card.card_type == :new

      {answered_card_changeset, card_log} = CardStateMachine.answer_card(card, :good, Duration.parse!("PT3M15S"), config)

      # assert answered_card_changeset.changes == %{card_type: :learn}

      assert card_log.ease_factor == 2.5
      assert card_log.time_to_answer == Duration.parse!("PT2M")
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

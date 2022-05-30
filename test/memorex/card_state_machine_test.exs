defmodule Memorex.CardStateMachineTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Cards.Card
  alias Memorex.{CardStateMachine, Config}

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
end

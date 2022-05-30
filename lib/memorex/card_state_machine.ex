defmodule Memorex.CardStateMachine do
  @moduledoc false

  alias Memorex.Cards.Card
  alias Memorex.Config

  @spec answer_card(Card.t(), Card.answer_choice(), Config.t()) :: map()
  def answer_card(%Card{card_type: :learn} = _card, :again, config) do
    %{remaining_steps: length(config.learn_steps)}
  end

  def answer_card(%Card{card_type: :learn} = _card, :hard, _config) do
    %{}
  end

  def answer_card(%Card{card_type: :learn, remaining_steps: 0} = _card, :good, _config) do
    %{card_type: :review}
  end

  def answer_card(%Card{card_type: :learn} = card, :good, _config) do
    %{remaining_steps: card.remaining_steps - 1}
  end

  def answer_card(%Card{card_type: :learn} = _card, :easy, _config) do
    %{card_type: :review}
  end
end

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

  def answer_card(%Card{card_type: :learn, remaining_steps: 0} = _card, :good, config) do
    %{card_type: :review, ease_factor: config.initial_ease, interval: config.graduating_interval_good}
  end

  def answer_card(%Card{card_type: :learn} = card, :good, _config) do
    %{remaining_steps: card.remaining_steps - 1}
  end

  def answer_card(%Card{card_type: :learn} = _card, :easy, config) do
    %{card_type: :review, ease_factor: config.initial_ease, interval: config.graduating_interval_easy}
  end
end

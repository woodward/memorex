defmodule Memorex.CardStateMachine do
  @moduledoc false

  alias Memorex.Cards.Card
  alias Memorex.Config
  alias Timex.Duration

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

  def answer_card(%Card{card_type: :review} = card, :again, _config) do
    %{ease_factor: card.ease_factor - 0.2, card_type: :relearn, remaining_steps: 0}
  end

  def answer_card(%Card{card_type: :review} = card, :hard, config) do
    scale = card.ease_factor * config.hard_multiplier * config.interval_multiplier
    %{ease_factor: card.ease_factor - 0.15, interval: Duration.scale(card.interval, scale)}
  end

  def answer_card(%Card{card_type: :review} = card, :good, config) do
    scale = card.ease_factor * config.interval_multiplier
    %{interval: Duration.scale(card.interval, scale)}
  end

  def answer_card(%Card{card_type: :review} = card, :easy, config) do
    scale = card.ease_factor * config.interval_multiplier * config.easy_multiplier
    %{ease_factor: card.ease_factor + 0.15, interval: Duration.scale(card.interval, scale)}
  end

  def answer_card(%Card{card_type: :relearn} = _card, :again, _config) do
    %{card_type: :relearn, remaining_steps: 0}
  end
end

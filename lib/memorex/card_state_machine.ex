defmodule Memorex.CardStateMachine do
  @moduledoc false

  alias Memorex.Cards.Card
  alias Memorex.Config
  alias Timex.Duration

  @spec answer_card(Card.t(), Card.answer_choice(), Config.t(), DateTime.t()) :: map()

  # --------------- Learn Cards ----------------------------------------------------------------------------------------

  def answer_card(%Card{card_type: :learn} = _card, :again, _config, _time_now) do
    %{current_step: 0}
  end

  def answer_card(%Card{card_type: :learn} = _card, :hard, _config, _time_now) do
    %{}
  end

  def answer_card(%Card{card_type: :learn} = card, :good, config, _time_now) do
    current_step = card.current_step + 1

    if current_step >= length(config.learn_steps) do
      %{card_type: :review, current_step: nil, ease_factor: config.initial_ease, interval: config.graduating_interval_good}
    else
      {interval, _rest} = config.learn_steps |> List.pop_at(current_step)
      %{current_step: current_step, interval: interval}
    end
  end

  def answer_card(%Card{card_type: :learn} = _card, :easy, config, _time_now) do
    %{card_type: :review, ease_factor: config.initial_ease, interval: config.graduating_interval_easy}
  end

  # --------------- Review Cards ---------------------------------------------------------------------------------------

  def answer_card(%Card{card_type: :review} = card, :again, config, _time_now) do
    interval = Duration.scale(card.interval, config.lapse_multiplier)
    # Or should interval = first relearn step???

    ease_factor = card.ease_factor + config.ease_again
    lapses = card.lapses + 1
    %{card_type: :relearn, lapses: lapses, ease_factor: ease_factor, current_step: 0, interval: interval}
  end

  def answer_card(%Card{card_type: :review} = card, :hard, config, _time_now) do
    scale = config.hard_multiplier * config.interval_multiplier
    ease_factor = card.ease_factor + config.ease_hard
    interval = Duration.scale(card.interval, scale) |> cap_duration(config.max_review_interval)
    %{ease_factor: ease_factor, interval: interval}
  end

  def answer_card(%Card{card_type: :review} = card, :good, config, time_now) do
    gap_between_due_and_now = Timex.diff(time_now, card.due, :duration)
    half_of_gap_between_due_and_now = Duration.scale(gap_between_due_and_now, 0.5)
    scale = card.ease_factor * config.interval_multiplier
    ease_factor = card.ease_factor + config.ease_good

    interval =
      Duration.add(card.interval, half_of_gap_between_due_and_now)
      |> Duration.scale(scale)
      |> cap_duration(config.max_review_interval)

    %{ease_factor: ease_factor, interval: interval}
  end

  def answer_card(%Card{card_type: :review} = card, :easy, config, time_now) do
    gap_between_due_and_now = Timex.diff(time_now, card.due, :duration)
    scale = card.ease_factor * config.interval_multiplier * config.easy_multiplier
    ease_factor = card.ease_factor + config.ease_easy

    interval =
      Duration.add(card.interval, gap_between_due_and_now)
      |> Duration.scale(scale)
      |> cap_duration(config.max_review_interval)

    %{ease_factor: ease_factor, interval: interval}
  end

  # --------------- Re-Learn Cards -------------------------------------------------------------------------------------

  def answer_card(%Card{card_type: :relearn} = _card, :again, _config, _time_now) do
    %{current_step: 0}
  end

  def answer_card(%Card{card_type: :relearn} = _card, :hard, _config, _time_now) do
    %{}
  end

  def answer_card(%Card{card_type: :relearn} = card, :good, config, _time_now) do
    current_step = card.current_step + 1

    if current_step >= length(config.relearn_steps) do
      %{card_type: :review, interval: config.min_review_interval, current_step: nil}
    else
      {interval, _rest} = config.relearn_steps |> List.pop_at(current_step)
      %{current_step: current_step, interval: interval}
    end
  end

  def answer_card(%Card{card_type: :relearn} = _card, :easy, config, _time_now) do
    interval = Duration.add(config.min_review_interval, config.relearn_easy_adj)
    %{card_type: :review, interval: interval, current_step: nil}
  end

  # --------------- Utilities ------------------------------------------------------------------------------------------

  @spec cap_duration(Duration.t(), Duration.t()) :: Duration.t()
  def cap_duration(duration, max_duration) do
    if Duration.to_seconds(duration) <= Duration.to_seconds(max_duration) do
      duration
    else
      max_duration
    end
  end
end

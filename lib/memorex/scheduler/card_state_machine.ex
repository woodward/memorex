defmodule Memorex.Scheduler.CardStateMachine do
  @moduledoc false

  alias Memorex.Domain.Card
  alias Memorex.Scheduler.Config
  alias Timex.Duration

  @spec answer_card(Card.t(), Card.answer_choice(), Config.t(), DateTime.t()) :: map()

  # --------------- New Cards ------------------------------------------------------------------------------------------

  def convert_new_card_to_learn_card(%Card{card_type: :new} = _card, config, time_now) do
    %{
      card_queue: :learn,
      card_type: :learn,
      current_step: 0,
      due: time_now,
      interval: config.learn_steps |> List.first(),
      lapses: 0,
      reps: 0
    }
  end

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
    interval_prior_to_lapse = card.interval
    scaled_interval = Duration.scale(card.interval, config.lapse_multiplier)

    interval =
      if Duration.to_seconds(scaled_interval) < Duration.to_seconds(config.min_review_interval) do
        config.min_review_interval
      else
        scaled_interval
      end

    ease_factor = card.ease_factor + config.ease_again
    lapses = card.lapses + 1

    %{
      card_type: :relearn,
      current_step: 0,
      ease_factor: ease_factor,
      interval_prior_to_lapse: interval_prior_to_lapse,
      interval: interval,
      lapses: lapses
    }
  end

  def answer_card(%Card{card_type: :review} = card, :hard, config, _time_now) do
    # Note that interval_scale doesn't multiply by ease_factor for this case
    interval_scale = config.hard_multiplier * config.interval_multiplier
    ease_factor = card.ease_factor + config.ease_hard
    interval = Duration.scale(card.interval, interval_scale) |> cap_duration(config.max_review_interval)
    %{ease_factor: ease_factor, interval: interval}
  end

  def answer_card(%Card{card_type: :review} = card, :good, config, time_now) do
    gap =
      case Timex.compare(card.due, time_now) do
        -1 -> Timex.diff(time_now, card.due, :duration) |> Duration.scale(0.5)
        _ -> Duration.parse!("PT0S")
      end

    interval_scale = card.ease_factor * config.interval_multiplier
    ease_factor = card.ease_factor + config.ease_good

    interval =
      Duration.add(card.interval, gap)
      |> Duration.scale(interval_scale)
      |> cap_duration(config.max_review_interval)

    %{ease_factor: ease_factor, interval: interval}
  end

  def answer_card(%Card{card_type: :review} = card, :easy, config, time_now) do
    gap =
      case Timex.compare(card.due, time_now) do
        -1 -> Timex.diff(time_now, card.due, :duration)
        _ -> Duration.parse!("PT0S")
      end

    interval_scale = card.ease_factor * config.interval_multiplier * config.easy_multiplier
    ease_factor = card.ease_factor + config.ease_easy

    interval =
      Duration.add(card.interval, gap)
      |> Duration.scale(interval_scale)
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
      %{card_type: :review, interval: config.min_review_interval, current_step: nil, interval_prior_to_lapse: nil}
    else
      {interval, _rest} = config.relearn_steps |> List.pop_at(current_step)
      %{current_step: current_step, interval: interval}
    end
  end

  def answer_card(%Card{card_type: :relearn} = _card, :easy, config, _time_now) do
    interval = Duration.add(config.min_review_interval, config.relearn_easy_adj)
    %{card_type: :review, interval: interval, current_step: nil, interval_prior_to_lapse: nil}
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

defmodule Memorex.Scheduler.CardStateMachine do
  @moduledoc """
  This is the heart of the Anki SM-2 algorithm.  Note that this file consists of pure functions; `Memorex.Domain.Card`
  structs come into the `answer_card/4` function, and a map containing changes are returned.  There is no database
  interaction in this file. Time is deterministic (i.e., there are no `Timex.now()` calls within this module), and the
  specific value of the current time is fed into each function.  `Memorex.Scheduler.CardStateMachine` is not truly a
  state machine per se (as it actually maintains no state), but is really a set of transforms on `Memorex.Domain.Card`s.
  """

  alias Memorex.Domain.Card
  alias Memorex.Scheduler.Config
  alias Timex.Duration

  # --------------- New Cards ------------------------------------------------------------------------------------------
  @spec convert_new_card_to_learn_card(Card.t(), Config.t(), DateTime.t()) :: map()
  def convert_new_card_to_learn_card(%Card{card_type: :new} = _card, config, time_now) do
    %{
      card_type: :learn,
      current_step: 0,
      due: time_now,
      interval: config.learn_steps |> List.first(),
      lapses: 0,
      reps: 0
    }
  end

  @doc """
  This is the main function used when drilling/reviewing `Memorex.Domain.Card`s.  Cards start out as `:new`, and then
  progress to `:learn` and then `:review` based on the Anki algorithm.  If a `:review` card is failed (by answering
  `:again`), then it becomes a `:relearn` card.

  Note that a map containing the difference in the card state is returned by `answer_card/4`, not a new version of the
  card.  Only values that actually modified by the answer are returned in this map.

  Also note that `Memorex.Domain.Card` values such as `:reps` are incremented outside of
  `Memorex.Scheduler.CardStateMachine` in `Memorex.Scheduler.CardReviewer` (otherwise every function in this file would
  increment `:rep` by one, which seemed redundant).  The `:due` field on `Memorex.Domain.Card` is also computed outside
  of `Memorex.Scheduler.CardStateMachine` based on the value of `:interval`; i.e., a new `:interval` is computed in
  `Memorex.Scheduler.CardStateMachine` and its value is added to the old `:due` datetime to find a new `:due` in
  `Memorex.Scheduler.CardReviewer`.

  """
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
    {card_type, interval_prior_to_lapse} =
      if Enum.empty?(config.relearn_steps) do
        {:review, nil}
      else
        {:relearn, card.interval}
      end

    scaled_interval = Duration.scale(card.interval, config.lapse_multiplier)

    interval =
      if Duration.to_seconds(scaled_interval) < Duration.to_seconds(config.min_review_interval) do
        config.min_review_interval
      else
        scaled_interval
      end

    ease_factor = (card.ease_factor + config.ease_again) |> floor_for_ease_factor(config.ease_minimum)
    lapses = card.lapses + 1

    changes = %{
      card_type: card_type,
      current_step: 0,
      ease_factor: ease_factor,
      interval_prior_to_lapse: interval_prior_to_lapse,
      interval: interval,
      lapses: lapses
    }

    if lapses >= config.leech_threshold, do: Map.put(changes, :card_status, :suspended), else: changes
  end

  def answer_card(%Card{card_type: :review} = card, :hard, config, _time_now) do
    # Note that interval_scale doesn't multiply by ease_factor for this case
    interval_scale = config.hard_multiplier * config.interval_multiplier
    ease_factor = (card.ease_factor + config.ease_hard) |> floor_for_ease_factor(config.ease_minimum)
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

  def answer_card(%Card{card_type: :relearn} = card, :easy, config, _time_now) do
    # interval = Duration.add(config.min_review_interval, config.relearn_easy_adj)

    # I think it should be this instead:
    interval = Duration.add(card.interval, config.relearn_easy_adj)
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

  @spec floor_for_ease_factor(float(), float()) :: float()
  defp floor_for_ease_factor(ease_factor, ease_minimum) do
    if ease_factor < ease_minimum, do: ease_minimum, else: ease_factor
  end
end

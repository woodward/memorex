defmodule Memorex.SchedulerCurrentlyUnused do
  @moduledoc false

  alias Memorex.Cards.Card
  alias Memorex.Config

  @spec is_card_due?(Card.t(), Config.t(), DateTime.t() | nil) :: boolean()
  def is_card_due?(%Card{card_queue: :new} = _card, _config, _now), do: true
  def is_card_due?(%Card{card_queue: :buried}, _config, _now), do: false
  def is_card_due?(%Card{card_queue: :suspended}, _config, _now), do: false

  def is_card_due?(%Card{card_queue: :learn} = card, config, now) do
    case DateTime.compare(card.due, learn_ahead_time(config, now)) do
      :gt -> false
      _ -> true
    end
  end

  def is_card_due?(%Card{card_queue: :day_learn} = card, _config, now) do
    case DateTime.compare(card.due, Timex.end_of_day(now)) do
      :gt -> false
      _ -> true
    end
  end

  def is_card_due?(%Card{card_queue: :review} = card, _config, now) do
    case DateTime.compare(card.due, Timex.end_of_day(now)) do
      :gt -> false
      _ -> true
    end
  end

  @spec learn_ahead_time(Config.t(), DateTime.t() | nil) :: DateTime.t()
  def learn_ahead_time(config, now \\ Timex.now()) do
    Timex.add(now, config.learn_ahead_time_interval)
  end
end

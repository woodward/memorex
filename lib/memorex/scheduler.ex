defmodule Memorex.Scheduler do
  @moduledoc false

  alias Memorex.Cards.Card
  alias Memorex.Config

  # I'm not sure what is up with this spec...
  # @spec answer_card(Card.t(), Card.answer_choice(), __MODULE__.Config.t()) :: Card.t()
  def answer_card(card, answer_choice, _scheduler_config) do
    if is_card_due?(card, answer_choice) do
      %{card | card_queue: :learn, card_type: :learn, due: Timex.now()}
    else
      card
    end
  end

  @spec is_card_due?(Card.t(), DateTime.t() | nil) :: boolean()
  def is_card_due?(%Card{card_queue: :new} = _card, _now), do: true
  def is_card_due?(%Card{card_queue: :buried}, _now), do: false
  def is_card_due?(%Card{card_queue: :suspended}, _now), do: false

  def is_card_due?(%Card{card_queue: :learn} = card, now) do
    case DateTime.compare(card.due, learn_ahead_time(now)) do
      :gt -> false
      _ -> true
    end
  end

  def is_card_due?(%Card{card_queue: :day_learn} = card, now) do
    case DateTime.compare(card.due, Timex.end_of_day(now)) do
      :gt -> false
      _ -> true
    end
  end

  def is_card_due?(%Card{card_queue: :review} = card, now) do
    case DateTime.compare(card.due, Timex.end_of_day(now)) do
      :gt -> false
      _ -> true
    end
  end

  @spec learn_ahead_time(DateTime.t() | nil) :: DateTime.t()
  def learn_ahead_time(now \\ Timex.now()) do
    config = %Config{}
    Timex.add(now, config.learn_ahead_time_interval)
  end
end

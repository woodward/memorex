defmodule Memorex.CardReviewer do
  @moduledoc false

  alias Timex.Duration
  alias Memorex.{Cards, CardStateMachine, Config, Repo}
  alias Memorex.Cards.{Card, CardLog}

  @spec answer_card_and_create_log_entry(Card.t(), Card.answer_choice(), DateTime.t(), DateTime.t(), Config.t()) :: {Card.t(), CardLog.t()}
  def answer_card_and_create_log_entry(card_before, answer, start_time, time_now, config) do
    card_after = answer_card(card_before, answer, time_now, config)
    time_to_answer = time_to_answer(start_time, time_now, config)
    card_log = CardLog.new(answer, card_before, card_after, time_to_answer) |> Repo.insert!() |> Repo.preload([:card, :note])
    {card_after, card_log}
  end

  @spec answer_card(Card.t(), Card.answer_choice(), DateTime.t(), Config.t()) :: Card.t()
  def answer_card(card_before, answer, time_now, config) do
    changes = CardStateMachine.answer_card(card_before, answer, config, time_now)
    Cards.update_card!(card_before, changes, time_now)
  end

  @spec time_to_answer(DateTime.t(), DateTime.t(), Config.t()) :: Duration.t()
  def time_to_answer(start_time, end_time, config) do
    Timex.diff(end_time, start_time, :duration) |> bracket_time_to_answer(config)
  end

  @spec bracket_time_to_answer(Duration.t(), Config.t()) :: Duration.t()
  def bracket_time_to_answer(time_to_answer, config) do
    time_to_answer_in_sec = Duration.to_seconds(time_to_answer)

    if time_to_answer_in_sec > Duration.to_seconds(config.min_time_to_answer) do
      if time_to_answer_in_sec > Duration.to_seconds(config.max_time_to_answer) do
        config.max_time_to_answer
      else
        time_to_answer
      end
    else
      config.min_time_to_answer
    end
  end
end

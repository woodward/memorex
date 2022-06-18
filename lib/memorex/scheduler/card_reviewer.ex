defmodule Memorex.Scheduler.CardReviewer do
  @moduledoc """
  `Memorex.Scheduler.CardReviewer` is used by the `MemorexWeb.ReviewLive` Live View to review cards.  `Meorex.Domain.Card`s
  are answered, and in the process `Memorex.Domain.CardLog`s are created.

  Note that in contrast to `Memorex.Scheduler.CardStateMachine`, `Memorex.Scheduler.CardReviewer` writes content to
  the database (the updated `Memorex.Domain.Card`, along with the `Memorex.Domain.CardLog`.)
  """

  alias Timex.Duration
  alias Memorex.Cards
  alias Memorex.Scheduler.{CardStateMachine, Config}
  alias Memorex.Ecto.Repo
  alias Memorex.Domain.{Card, CardLog}

  @doc "Answers a `Memorex.Domain.Card`, and updates it in the database (and also creates a `Memorex.Domain.CardLog`)"
  @spec answer_card_and_create_log_entry(Card.t(), Card.answer_choice(), DateTime.t(), DateTime.t(), Config.t()) :: {Card.t(), CardLog.t()}
  def answer_card_and_create_log_entry(card_before, answer, start_time, time_now, config) do
    card_after = answer_card(card_before, answer, time_now, config)
    time_to_answer = time_to_answer(start_time, time_now, config)
    card_log = CardLog.new(answer, card_before, card_after, time_to_answer) |> Repo.insert!() |> Repo.preload([:card, :note])
    {card_after, card_log}
  end

  @doc "Answers a `Memorex.Domain.Card`, and updates it in the database (note no `Memorex.Domain.CardLog` is created)"
  @spec answer_card(Card.t(), Card.answer_choice(), DateTime.t(), Config.t()) :: Card.t()
  def answer_card(card_before, answer, time_now, config) do
    changes = CardStateMachine.answer_card(card_before, answer, config, time_now)
    Cards.update_card_when_reviewing!(card_before, changes, time_now)
  end

  @doc """
  Computes the time to answer this card.  Note that the time to answer is bracketed by `:min_time_to_answer` and
  `:max_time_to_answer` on `Memorex.Scheduler.Config`.  The thought is that if you walk away from the computer when
  drilling, the stored `time_to_answer` will be stored as at most `:max_time_to_answer`.
  """
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

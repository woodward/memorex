defmodule Memorex.Driller do
  @moduledoc false

  alias Timex.Duration
  alias Memorex.{CardStateMachine, Config, Repo}
  alias Memorex.Cards.{Card, CardLog}

  @spec answer_card(Card.t(), Card.answer_choice(), DateTime.t(), Config.t()) :: :ok
  def answer_card(card, answer, start_time, config) do
    changes = CardStateMachine.answer_card(card, answer, config)
    {:ok, answered_card} = Card.changeset(card, changes) |> Repo.update()
    time_to_answer = Timex.diff(start_time, Timex.now(), :duration) |> bracket_time_to_answer(config)
    card_log = CardLog.new(answer, card, answered_card, time_to_answer)
    Repo.insert!(card_log)
  end

  @spec bracket_time_to_answer(Duration.t(), Config.t()) :: Duration.t()
  def bracket_time_to_answer(time_to_answer, config \\ %Config{}) do
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

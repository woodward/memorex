defmodule Memorex.CardStateMachine do
  @moduledoc false

  alias Memorex.Cards.{Card, CardLog}
  alias Memorex.Config
  alias Timex.Duration

  @spec answer_card(Card.t(), Card.answer_choice(), Duration.t(), Config.t()) :: {Ecto.Changeset.t(), CardLog.t()}
  def answer_card(card, answer, time_to_answer, config) do
    card_changeset = Card.changeset(card)
    card_log = CardLog.new(answer, card, card_changeset, bracket_time_to_answer(time_to_answer, config))
    {card_changeset, card_log}
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

defmodule Memorex.Cards do
  @moduledoc false

  alias Memorex.Schema.{Card, CardLog}

  @spec answer_card(Card.t(), CardLog.answer_choice(), Timex.Duration.t()) :: nil
  def answer_card(_card, _choice, _time_to_answer) do
    nil
  end

  @spec next_intervals(Card.t()) :: nil
  def next_intervals(_card) do
    nil
  end
end

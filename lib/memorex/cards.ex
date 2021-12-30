defmodule Memorex.Cards do
  @moduledoc false

  alias Memorex.Card

  @spec answer_card(Card.t(), Card.answer_choice(), Timex.Duration.t()) :: nil
  def answer_card(_card, _choice, _time_to_answer) do
    nil
  end

  def next_intervals(_card) do
    nil
  end
end

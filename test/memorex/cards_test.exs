defmodule Memorex.CardsTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Schema.Card
  alias Memorex.Cards

  test "next_intervals/1" do
    card = %Card{}
    Cards.next_intervals(card)
  end

  test "answer_card/3" do
    card = %Card{}
    answer_choice = :again
    time_to_answer = nil
    Cards.answer_card(card, answer_choice, time_to_answer)
  end
end

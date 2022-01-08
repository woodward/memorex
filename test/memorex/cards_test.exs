defmodule Memorex.CardsTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Cards
  alias Memorex.Schema.Card

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

  describe "is_card_due?/2" do
    test "is true for| a card in the new queue" do
      now = Timex.now()
      three_minutes_from_now = Timex.shift(now, minutes: 3)
      card = %Card{card_queue: :new, due: three_minutes_from_now}
      assert Cards.is_card_due?(card, now) == true
    end

    test "is true for a :learn card if the card due date is less than today" do
      now = Timex.now()
      three_minutes_ago = Timex.shift(now, minutes: -3)
      card = %Card{card_queue: :learn, due: three_minutes_ago}
      assert Cards.is_card_due?(card, now) == true
    end

    test "is false for a :learn card if the card due date is greater than or equal to today" do
      now = Timex.now()
      three_minutes_from_now = Timex.shift(now, minutes: 3)
      card = %Card{card_queue: :learn, due: three_minutes_from_now}
      assert Cards.is_card_due?(card, now) == false

      card = %Card{card_queue: :learn, due: now}
      assert Cards.is_card_due?(card, now) == false
    end
  end
end

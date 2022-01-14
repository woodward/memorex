defmodule Memorex.SchedulerTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Scheduler
  alias Memorex.Schema.Card

  describe "learn_ahead_time" do
    test "uses the config :learn_ahead_time_inveral value" do
      now = ~U[2021-01-01 10:30:00Z]
      learn_ahead_time_twenty_minutes_from_now = Scheduler.learn_ahead_time(now)
      assert learn_ahead_time_twenty_minutes_from_now == ~U[2021-01-01 10:50:00Z]
    end
  end

  describe "is_card_due?/2" do
    test "is true for a card in the new queue, regardless of anything else" do
      now = Timex.now()
      three_minutes_from_now = Timex.shift(now, minutes: 3)
      card = %Card{card_queue: :new, due: three_minutes_from_now}
      assert Scheduler.is_card_due?(card, now) == true
    end

    test "is true for a :learn card if the card due date is less than now plus the learn-ahead time" do
      now = Timex.now()
      nineteen_minutes_from_now = Timex.shift(now, minutes: 19)
      card = %Card{card_queue: :learn, due: nineteen_minutes_from_now}
      assert Scheduler.is_card_due?(card, now) == true

      twenty_minutes_from_now = Timex.shift(now, minutes: 20)
      card = %Card{card_queue: :learn, due: twenty_minutes_from_now}
      assert Scheduler.is_card_due?(card, now) == true
    end

    test "is false for a :learn card if the card due date is greater than now plus the learn-ahead time" do
      now = Timex.now()
      thirty_minutes_from_now = Timex.shift(now, minutes: 30)
      card = %Card{card_queue: :learn, due: thirty_minutes_from_now}
      assert Scheduler.is_card_due?(card, now) == false
    end

    test "is true for a :day_learn card if the card due date is less than the end of today" do
      now = Timex.now()
      nineteen_minutes_from_now = Timex.shift(now, minutes: 19)
      card = %Card{card_queue: :day_learn, due: nineteen_minutes_from_now}
      assert Scheduler.is_card_due?(card, now) == true
    end

    test "is false for a :day_learn card if the card due date is less than the end of today" do
      now = Timex.now()
      one_day_from_now = Timex.shift(now, days: 1)
      card = %Card{card_queue: :day_learn, due: one_day_from_now}
      assert Scheduler.is_card_due?(card, now) == false
    end

    test "is true for a :review card if the card due date is less than the end of today" do
      now = Timex.now()
      nineteen_minutes_from_now = Timex.shift(now, minutes: 19)
      card = %Card{card_queue: :review, due: nineteen_minutes_from_now}
      assert Scheduler.is_card_due?(card, now) == true
    end

    test "is false for a :review card if the card due date is less than the end of today" do
      now = Timex.now()
      one_day_from_now = Timex.shift(now, days: 1)
      card = %Card{card_queue: :review, due: one_day_from_now}
      assert Scheduler.is_card_due?(card, now) == false
    end

    test "is false for a :buried card" do
      now = Timex.now()
      one_minute_from_now = Timex.shift(now, minutes: 1)
      card = %Card{card_queue: :buried, due: one_minute_from_now}
      assert Scheduler.is_card_due?(card, now) == false
    end

    test "is false for a :suspended card" do
      now = Timex.now()
      one_minute_from_now = Timex.shift(now, minutes: 1)
      card = %Card{card_queue: :suspended, due: one_minute_from_now}
      assert Scheduler.is_card_due?(card, now) == false
    end
  end

  describe "answer_card" do
    test "returns with no action if the card is not due" do
      now = Timex.now()
      card = %Card{card_queue: :buried, due: now, card_type: :learn}
      assert Scheduler.is_card_due?(card, now) == false

      scheduler_config = %Scheduler.Config{}
      answered_card = Scheduler.answer_card(card, :hard, scheduler_config)
      assert answered_card == card
    end
  end

  describe "implemented tests from Anki" do
    test "test_new" do
      # Corresponds to test_new() in test_schedv2.py in Anki
      now = Timex.now()
      scheduler_config = %Scheduler.Config{}
      card = %Card{}
      card = Scheduler.answer_card(card, :again, scheduler_config)
      assert card.card_queue == :learn
      assert card.card_type == :learn

      # Can this assertion be made more specific?
      assert DateTime.compare(card.due, now) == :gt
    end

    test "test_learn" do
      # Corresponds to test_learn() in test_schedv2.py in Anki
    end
  end

  describe "future tests from Anki" do
    @tag :skip
    test "test_clock" do
      # Corresponds to test_clock() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_basics" do
      # Corresponds to test_basics() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_learn_day" do
      # Corresponds to test_learn_day() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_reviews" do
      # Corresponds to test_reviews() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_review_limits" do
      # Corresponds to test_review_limits() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_button_spacing" do
      # Corresponds to test_button_spacing() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_overdue_lapse" do
      # Corresponds to test_overdue_lapse() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_nextIvl" do
      # Corresponds to test_nextIvl() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_bury" do
      # Corresponds to test_bury() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_suspend" do
      # Corresponds to test_suspend() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_filt_reviewing_early_normal" do
      # Corresponds to test_filt_reviewing_early_normal() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_relearn" do
      # Corresponds to test_relearn() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_learn_collapsed" do
      # Corresponds to test_learn_collapsed() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_relearn_no_steps" do
      # Corresponds to test_relearn_no_steps() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_newLimits" do
      # Corresponds to test_newLimits() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_newBoxes" do
      # Corresponds to test_newBoxes() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_filt_keep_lrn_state" do
      # Correponds to test_filt_keep_lrn_state() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_preview" do
      # Correponds to test_preview() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_ordcycle" do
      # Correponds to test_ordcycle() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_counts_idx" do
      # Correponds to test_counts_idx() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_counts_idx_new" do
      # Correponds to test_counts_idx_new() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_repCounts" do
      # Correponds to test_repCounts() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_timing" do
      # Correponds to test_timing() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_collapse" do
      # Correponds to test_collapse() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_deckDue" do
      # Correponds to test_deckDue() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_deckTree" do
      # Correponds to test_deckTree() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_deckFlow" do
      # Correponds to test_deckFlow() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_reorder" do
      # Correponds to test_reorder() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_forget" do
      # Correponds to test_forget() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_resched" do
      # Correponds to test_resched() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_norelearn" do
      # Correponds to test_norelearn() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_failmult" do
      # Correponds to test_failmult() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_negativeDueFilter" do
      # Correponds to test_negativeDueFilter() in test_schedv2.py in Anki
    end

    @tag :skip
    test "test_initial_repeat" do
      # Correponds to test_initial_repeat() in test_schedv2.py in Anki
    end
  end
end

defmodule Memorex.SchedulerTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Scheduler
  alias Memorex.Schema.Card

  describe "implemented tests from Anki" do
    test "test_new" do
      # Corresponds to test_new() in test_schedv2.py in Anki
      now = Timex.now()
      scheduler_config = %Scheduler.Config{}
      card = %Card{}
      card = Scheduler.answer_card(card, :again, scheduler_config)
      assert card.card_queue == :learn
      assert card.card_type == :learn
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

defmodule Memorex.SchedulerTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Scheduler
  alias Memorex.Schema.Card

  test "new" do
    # Corresponds to test_new() in test_schedv2.py in Anki
    now = Timex.now()
    scheduler_config = %Scheduler.Config{}
    card = %Card{}
    card = Scheduler.answer_card(card, :again, scheduler_config)
    assert card.card_queue == :learn
    assert card.card_type == :learn
    assert DateTime.compare(card.due, now) == :gt
  end
end

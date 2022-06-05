defmodule Memorex.SchedulerCurrentlyUnusedCurrentlyUnusedTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{Config, SchedulerCurrentlyUnused}
  alias Memorex.Cards.Card
  alias Timex.Duration

  describe "learn_ahead_time" do
    test "uses the config :learn_ahead_time_interval value" do
      now = ~U[2021-01-01 10:30:00Z]
      config = %Config{learn_ahead_time_interval: Duration.parse!("PT20M")}
      learn_ahead_time_twenty_minutes_from_now = SchedulerCurrentlyUnused.learn_ahead_time(config, now)
      assert learn_ahead_time_twenty_minutes_from_now == ~U[2021-01-01 10:50:00Z]
    end
  end

  describe "is_card_due?/2" do
    setup do
      config = %Config{learn_ahead_time_interval: Duration.parse!("PT20M")}
      [config: config]
    end

    test "is true for a card in the new queue, regardless of anything else", %{config: config} do
      now = Timex.now()
      three_minutes_from_now = Timex.shift(now, minutes: 3)
      card = %Card{card_queue: :new, due: three_minutes_from_now}
      assert SchedulerCurrentlyUnused.is_card_due?(card, config, now) == true
    end

    test "is true for a :learn card if the card due date is less than now plus the learn-ahead time", %{config: config} do
      now = Timex.now()
      nineteen_minutes_from_now = Timex.shift(now, minutes: 19)
      card = %Card{card_queue: :learn, due: nineteen_minutes_from_now}
      assert SchedulerCurrentlyUnused.is_card_due?(card, config, now) == true

      twenty_minutes_from_now = Timex.shift(now, minutes: 20)
      card = %Card{card_queue: :learn, due: twenty_minutes_from_now}
      assert SchedulerCurrentlyUnused.is_card_due?(card, config, now) == true
    end

    test "is false for a :learn card if the card due date is greater than now plus the learn-ahead time", %{config: config} do
      now = Timex.now()
      thirty_minutes_from_now = Timex.shift(now, minutes: 30)
      card = %Card{card_queue: :learn, due: thirty_minutes_from_now}
      assert SchedulerCurrentlyUnused.is_card_due?(card, config, now) == false
    end

    test "is true for a :day_learn card if the card due date is less than the end of today", %{config: config} do
      now = Timex.now()
      nineteen_minutes_from_now = Timex.shift(now, minutes: 19)
      card = %Card{card_queue: :day_learn, due: nineteen_minutes_from_now}
      assert SchedulerCurrentlyUnused.is_card_due?(card, config, now) == true
    end

    test "is false for a :day_learn card if the card due date is greater than the end of today", %{config: config} do
      now = Timex.now()
      one_day_from_now = Timex.shift(now, days: 1)
      card = %Card{card_queue: :day_learn, due: one_day_from_now}
      assert SchedulerCurrentlyUnused.is_card_due?(card, config, now) == false
    end

    test "is true for a :review card if the card due date is less than the end of today", %{config: config} do
      now = Timex.now()
      nineteen_minutes_from_now = Timex.shift(now, minutes: 19)
      card = %Card{card_queue: :review, due: nineteen_minutes_from_now}
      assert SchedulerCurrentlyUnused.is_card_due?(card, config, now) == true
    end

    test "is false for a :review card if the card due date is greater than the end of today", %{config: config} do
      now = Timex.now()
      one_day_from_now = Timex.shift(now, days: 1)
      card = %Card{card_queue: :review, due: one_day_from_now}
      assert SchedulerCurrentlyUnused.is_card_due?(card, config, now) == false
    end

    test "is false for a :buried card", %{config: config} do
      now = Timex.now()
      one_minute_from_now = Timex.shift(now, minutes: 1)
      card = %Card{card_queue: :buried, due: one_minute_from_now}
      assert SchedulerCurrentlyUnused.is_card_due?(card, config, now) == false
    end

    test "is false for a :suspended card", %{config: config} do
      now = Timex.now()
      one_minute_from_now = Timex.shift(now, minutes: 1)
      card = %Card{card_queue: :suspended, due: one_minute_from_now}
      assert SchedulerCurrentlyUnused.is_card_due?(card, config, now) == false
    end
  end
end

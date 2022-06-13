defmodule Memorex.Scheduler.CardReviewerTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Scheduler.{CardReviewer, CardStateMachine, Config}
  alias Memorex.Domain.{Card, Note}
  alias Timex.Duration

  describe "bracket_time_to_answer/1" do
    setup do
      config = %Config{min_time_to_answer: Duration.parse!("PT1S"), max_time_to_answer: Duration.parse!("PT1M")}
      [config: config]
    end

    test "returns the actual time to answer if it is not too large or too small", %{config: config} do
      time_to_answer = Duration.parse!("PT15S")
      assert CardReviewer.bracket_time_to_answer(time_to_answer, config) == Duration.parse!("PT15S")
    end

    test "returns the minimum time if the time to answer is too small", %{config: config} do
      time_to_answer = Duration.parse!("PT0S")
      assert CardReviewer.bracket_time_to_answer(time_to_answer, config) == Duration.parse!("PT1S")
    end

    test "returns the maximum time if the time to answer is too large", %{config: config} do
      time_to_answer = Duration.parse!("PT61S")
      assert CardReviewer.bracket_time_to_answer(time_to_answer, config) == Duration.parse!("PT1M")
    end
  end

  describe "time_to_answer/1" do
    setup do
      config = %Config{min_time_to_answer: Duration.parse!("PT1S"), max_time_to_answer: Duration.parse!("PT1M")}
      [config: config]
    end

    test "returns the actual time to answer if it is not too large or too small", %{config: config} do
      start_time = ~U[2022-01-01 12:00:00Z]
      end_time = ~U[2022-01-01 12:00:30Z]
      assert CardReviewer.time_to_answer(start_time, end_time, config) == Duration.parse!("PT30S")
    end

    test "returns the minimum time if the time to answer is too small", %{config: config} do
      start_time = ~U[2022-01-01 12:00:00Z]
      end_time = ~U[2022-01-01 12:00:00Z]
      assert CardReviewer.time_to_answer(start_time, end_time, config) == Duration.parse!("PT1S")
    end

    test "returns the maximum time if the time to answer is too large", %{config: config} do
      start_time = ~U[2022-01-01 12:00:00Z]
      end_time = ~U[2022-01-01 12:02:30Z]
      assert CardReviewer.time_to_answer(start_time, end_time, config) == Duration.parse!("PT1M")
    end
  end

  describe "answer_card_and_create_log_entry" do
    test "answers the card, and creates a log entry" do
      note = %Note{content: ["First", "Second"]}

      card = %Card{
        card_type: :review,
        interval: Duration.parse!("PT4M"),
        ease_factor: 2.5,
        reps: 3,
        note: note,
        due: ~U[2021-12-24 12:00:00Z]
      }

      card = Repo.insert!(card)

      config = %Config{
        interval_multiplier: 1.0,
        ease_good: 0.0,
        max_time_to_answer: Duration.parse!("PT1M"),
        max_review_interval: Duration.parse!("P100Y"),
        min_time_to_answer: Duration.parse!("PT1S")
      }

      start_time = ~U[2022-01-01 12:02:00Z]
      time_now = ~U[2022-01-01 12:04:00Z]

      {card, card_log} = CardReviewer.answer_card_and_create_log_entry(card, :good, start_time, time_now, config)

      assert card_log.answer_choice == :good
      assert card_log.card_id == card.id
      assert card_log.card_type == :review
      assert card_log.ease_factor == 2.5
      assert card_log.interval == Duration.parse!("P10DT15M")
      assert card_log.last_interval == Duration.parse!("PT4M")
      assert card_log.time_to_answer == Duration.parse!("PT60S")

      # Verify preload works:
      assert card_log.card.ease_factor == 2.5
      assert card_log.note.content == ["First", "Second"]

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-11 12:19:00Z]
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("P10DT15M")
      assert card.current_step == nil
      assert card.reps == 4
    end
  end

  describe "answer_card/4" do
    # ======================== Learn Cards =============================================================================
    test "learn card - answer :again" do
      config = %Config{learn_steps: [Duration.parse!("PT2M"), Duration.parse!("PT15M")]}

      card =
        %Card{
          # card_queue: :review,
          card_type: :learn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: nil,
          interval: Duration.parse!("PT1M"),
          lapses: 0,
          current_step: 2,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :again, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :learn
      assert card.due == ~U[2022-01-01 12:01:00Z]
      assert card.ease_factor == nil
      assert card.interval == Duration.parse!("PT1M")
      assert card.lapses == 0
      assert card.current_step == 0
      assert card.reps == 4
    end

    test "learn card - answer :hard" do
      config = %Config{learn_steps: [Duration.parse!("PT2M"), Duration.parse!("PT15M")]}

      card =
        %Card{
          # card_queue: :review,
          card_type: :learn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: nil,
          interval: Duration.parse!("PT1M"),
          lapses: 0,
          current_step: 2,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :hard, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :learn
      assert card.due == ~U[2022-01-01 12:01:00Z]
      assert card.ease_factor == nil
      assert card.interval == Duration.parse!("PT1M")
      assert card.lapses == 0
      assert card.current_step == 2
      assert card.reps == 4
    end

    test "learn card - answer :good - advance one step" do
      config = %Config{learn_steps: [Duration.parse!("PT2M"), Duration.parse!("PT15M")]}

      card =
        %Card{
          # card_queue: :review,
          card_type: :learn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: nil,
          interval: Duration.parse!("PT1M"),
          lapses: 0,
          current_step: 0,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :learn
      assert card.due == ~U[2022-01-01 12:15:00Z]
      assert card.ease_factor == nil
      assert card.interval == Duration.parse!("PT15M")
      assert card.lapses == 0
      assert card.current_step == 1
      assert card.reps == 4
    end

    test "learn card - answer :good - become a review card" do
      config = %Config{
        initial_ease: 2.5,
        graduating_interval_good: Duration.parse!("P1D"),
        learn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")]
      }

      card =
        %Card{
          # card_queue: :review,
          card_type: :learn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: nil,
          interval: Duration.parse!("PT10M"),
          lapses: 0,
          current_step: 1,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-02 12:00:00Z]
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("P1D")
      assert card.lapses == 0
      assert card.current_step == nil
      assert card.reps == 4
    end

    # ======================== Review Cards ============================================================================
    test "review card - answer :again" do
      config = %Config{
        ease_again: -0.2,
        relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")],
        lapse_multiplier: 0.0,
        min_review_interval: Duration.parse!("P1D")
      }

      card =
        %Card{
          # card_queue: :review,
          card_type: :review,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("PT10M"),
          lapses: 0,
          current_step: 1,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :again, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :relearn
      assert card.due == ~U[2022-01-02 12:00:00Z]
      assert card.ease_factor == 2.3
      assert card.interval == Duration.parse!("P1D")
      assert card.lapses == 1
      assert card.current_step == 0
      assert card.reps == 4
    end

    test "review card - answer :hard" do
      config = %Config{interval_multiplier: 1.1, ease_hard: -0.15, hard_multiplier: 1.2, max_review_interval: Duration.parse!("P100Y")}

      card =
        %Card{
          # card_queue: :review,
          card_type: :review,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("P1D"),
          lapses: 0,
          current_step: 0,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :hard, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-02 19:40:48Z]
      assert card.ease_factor == 2.35
      assert card.interval == Duration.parse!("P1DT7H40M48S")
      assert card.lapses == 0
      assert card.current_step == 0
      assert card.reps == 4
    end

    test "review card - answer :good" do
      config = %Config{interval_multiplier: 1.1, ease_good: 0.1, max_review_interval: Duration.parse!("P100Y")}

      card =
        %Card{
          # card_queue: :review,
          card_type: :review,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("P1D"),
          lapses: 0,
          current_step: 0,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-04 06:00:00Z]
      assert card.ease_factor == 2.6
      assert card.interval == Duration.parse!("P2DT18H")
      assert card.lapses == 0
      assert card.current_step == 0
      assert card.reps == 4
    end

    test "review card - answer :easy" do
      config = %Config{interval_multiplier: 1.1, easy_multiplier: 1.3, ease_easy: 0.15, max_review_interval: Duration.parse!("P100Y")}

      card =
        %Card{
          # card_queue: :review,
          card_type: :review,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("P1D"),
          lapses: 0,
          current_step: 0,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :easy, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-05 01:48:00Z]
      assert card.ease_factor == 2.65
      assert card.interval == Duration.parse!("P3DT13H48M")
      assert card.lapses == 0
      assert card.current_step == 0
      assert card.reps == 4
    end

    # ======================== Relearn Cards ===========================================================================
    test "relearn card - answer :again" do
      config = %Config{relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")]}

      card =
        %Card{
          # card_queue: :review,
          card_type: :relearn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("PT10M"),
          lapses: 0,
          current_step: 1,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :again, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :relearn
      assert card.due == ~U[2022-01-01 12:10:00Z]
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("PT10M")
      assert card.lapses == 0
      assert card.current_step == 0
      assert card.reps == 4
    end

    test "relearn card - answer :hard" do
      config = %Config{relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")]}

      card =
        %Card{
          # card_queue: :review,
          card_type: :relearn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("PT10M"),
          lapses: 0,
          current_step: 1,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :hard, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :relearn
      assert card.due == ~U[2022-01-01 12:10:00Z]
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("PT10M")
      assert card.lapses == 0
      assert card.current_step == 1
      assert card.reps == 4
    end

    test "relearn card - answer :good - one remaining step" do
      config = %Config{relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")], min_review_interval: Duration.parse!("P1D")}

      card =
        %Card{
          # card_queue: :review,
          card_type: :relearn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("PT10M"),
          lapses: 0,
          current_step: 1,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-02 12:00:00Z]
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("P1D")
      assert card.lapses == 0
      assert card.current_step == nil
      assert card.reps == 4
    end

    test "relearn card - answer :easy - become a review card again" do
      config = %Config{
        relearn_steps: [Duration.parse!("PT10M"), Duration.parse!("PT20M")],
        min_review_interval: Duration.parse!("P1D"),
        relearn_easy_adj: Duration.parse!("P1D")
      }

      card =
        %Card{
          # card_queue: :review,
          card_type: :relearn,
          due: ~U[2022-01-01 12:00:00Z],
          ease_factor: 2.5,
          interval: Duration.parse!("PT10M"),
          lapses: 0,
          current_step: 1,
          reps: 3
        }
        |> Repo.insert!()

      card = CardReviewer.answer_card(card, :easy, ~U[2022-01-01 12:00:00Z], config)

      # assert card.card_queue == :review
      assert card.card_type == :review
      assert card.due == ~U[2022-01-03 12:00:00Z]
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("P2D")
      assert card.lapses == 0
      assert card.current_step == nil
      assert card.reps == 4
    end
  end

  describe "tests from anki - learn" do
    test "'test_learn' sequence (matches up with 'test_learn' in anki/pylib/tests/test_schedv2.py" do
      # Based on:
      # https://github.com/ankitects/anki/blob/1bab947c9c16f3725076462a702c880a083afe90/pylib/tests/test_schedv2.py#L149

      config = %Config{
        graduating_interval_good: Duration.parse!("P1D"),
        learn_steps: [
          Duration.parse!("PT30S"),
          Duration.parse!("PT3M"),
          Duration.parse!("PT10M")
        ]
      }

      time_now = ~U[2022-01-01 12:00:00Z]
      card = %Card{card_type: :new} |> Repo.insert!()
      updates = card |> CardStateMachine.convert_new_card_to_learn_card(config, time_now)
      card = card |> Card.changeset(updates) |> Repo.update!()

      assert card.card_type == :learn
      assert card.current_step == 0
      assert card.due == time_now
      assert card.ease_factor == nil
      assert card.interval == Duration.parse!("PT30S")
      assert card.lapses == 0
      assert card.reps == 0

      card = CardReviewer.answer_card(card, :again, ~U[2022-01-01 12:00:00Z], config)
      assert card.card_type == :learn
      assert card.current_step == 0
      assert card.due == ~U[2022-01-01 12:00:30Z]
      assert card.ease_factor == nil
      assert card.interval == Duration.parse!("PT30S")
      assert card.reps == 1

      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:05:00Z], config)
      assert card.card_type == :learn
      assert card.current_step == 1
      assert card.due == ~U[2022-01-01 12:08:00Z]
      assert card.ease_factor == nil
      assert card.interval == Duration.parse!("PT3M")
      assert card.reps == 2

      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:10:00Z], config)
      assert card.card_type == :learn
      assert card.current_step == 2
      assert card.due == ~U[2022-01-01 12:20:00Z]
      assert card.ease_factor == nil
      assert card.interval == Duration.parse!("PT10M")
      assert card.reps == 3

      card = CardReviewer.answer_card(card, :good, ~U[2022-01-01 12:20:00Z], config)
      assert card.card_type == :review
      assert card.current_step == nil
      assert card.ease_factor == nil
      assert card.interval == Duration.parse!("P1D")
      assert card.reps == 4

      # Not sure how to read this line: https://github.com/ankitects/anki/blob/1bab947c9c16f3725076462a702c880a083afe90/pylib/tests/test_schedv2.py#L196
      # From anki:     assert c.due == col.sched.today + 1
      # Is this just due on a certain day, but not at a certain time?
      assert card.due == ~U[2022-01-02 12:20:00Z]
    end
  end

  describe "tests from anki - reviews - 'test_reviews' sequence (matches up with 'test_reviews' in anki/pylib/tests/test_schedv2.py" do
    # Based on:
    # https://github.com/ankitects/anki/blob/1bab947c9c16f3725076462a702c880a083afe90/pylib/tests/test_schedv2.py#L359
    setup do
      config = %Config{
        ease_again: -0.2,
        ease_hard: -0.15,
        ease_good: 0.0,
        ease_easy: 0.15,
        #
        easy_multiplier: 1.3,
        hard_multiplier: 1.2,
        lapse_multiplier: 0.0,
        interval_multiplier: 1.0,
        #
        max_review_interval: Duration.parse!("P100Y"),
        min_review_interval: Duration.parse!("P1D")
      }

      time_now = ~U[2022-01-01 12:00:00Z]
      eight_days_ago = ~U[2021-12-24 12:00:00Z]

      card =
        %Card{
          card_type: :review,
          due: eight_days_ago,
          interval: Duration.parse!("P100D"),
          reps: 3,
          ease_factor: 2.5,
          lapses: 1
        }
        |> Repo.insert!()

      assert card.card_type == :review
      assert card.current_step == nil
      assert card.due == eight_days_ago
      assert card.ease_factor == 2.5
      assert card.interval == Duration.parse!("P100D")
      assert card.lapses == 1
      assert card.reps == 3

      [time_now: time_now, config: config, card: card]
    end

    test "answer :hard", %{time_now: time_now, config: config, card: card} do
      # https://github.com/ankitects/anki/blob/fbb0d909354b53e602151206dab442e92969b3a8/pylib/tests/test_schedv2.py#L381
      card = CardReviewer.answer_card(card, :hard, time_now, config)
      assert card.card_type == :review
      assert card.current_step == nil
      # https://www.convertunits.com/dates/120/daysfrom/Jan+1,+2022
      # Comment in Anki code: # the new interval should be (100) * 1.2 = 120
      assert card.due == ~U[2022-05-01 12:00:00Z]
      assert card.ease_factor == 2.35
      assert card.interval == Duration.parse!("P120D")
      assert card.lapses == 1
      assert card.reps == 4
    end

    test "answer :good", %{time_now: time_now, config: config, card: card} do
      # https://github.com/ankitects/anki/blob/fbb0d909354b53e602151206dab442e92969b3a8/pylib/tests/test_schedv2.py#L396
      card = CardReviewer.answer_card(card, :good, time_now, config)
      assert card.card_type == :review
      assert card.current_step == nil
      # https://www.convertunits.com/dates/260/daysfrom/Jan+1,+2022
      # Comment in Anki code:  # the new interval should be (100 + 8/2) * 2.5 = 260
      assert card.due == ~U[2022-09-18 12:00:00Z]
      assert card.ease_factor == 2.50
      assert card.interval == Duration.parse!("P260D")
      assert card.lapses == 1
      assert card.reps == 4
    end

    test "answer :easy", %{time_now: time_now, config: config, card: card} do
      # https://github.com/ankitects/anki/blob/fbb0d909354b53e602151206dab442e92969b3a8/pylib/tests/test_schedv2.py#L406
      card = CardReviewer.answer_card(card, :easy, time_now, config)
      assert card.card_type == :review
      assert card.current_step == nil
      # https://www.convertunits.com/dates/351/daysfrom/Jan+1,+2022
      # Comment in Anki code:  # the new interval should be (100 + 8) * 2.5 * 1.3 = 351
      assert card.due == ~U[2022-12-18 12:00:00Z]
      assert card.ease_factor == 2.65
      assert card.interval == Duration.parse!("P351D")
      assert card.lapses == 1
      assert card.reps == 4
    end
  end

  describe "tests from anki - relearn - 'test_relearn' sequence (matches up with 'test_relearn' in anki/pylib/tests/test_schedv2.py" do
    # Based on:
    # https://github.com/ankitects/anki/blob/4d51ee8a645fd1fd8b4116df25299139af07d518/pylib/tests/test_schedv2.py#L211

    test "fail the card and then immediately graduate it back to :review" do
      config = %Config{
        ease_again: -0.2,
        # ease_hard: -0.15,
        # ease_good: 0.0,
        # ease_easy: 0.15,
        # #
        # easy_multiplier: 1.3,
        # hard_multiplier: 1.2,
        lapse_multiplier: 0.0,
        # interval_multiplier: 1.0,
        # #
        # max_review_interval: Duration.parse!("P100Y"),
        min_review_interval: Duration.parse!("P1D")
      }

      time_now = ~U[2022-01-01 12:00:00Z]

      card =
        %Card{
          card_type: :review,
          due: time_now,
          interval: Duration.parse!("P100D"),
          reps: 3,
          ease_factor: 2.5,
          lapses: 1
        }
        |> Repo.insert!()

      [time_now: time_now, config: config, card: card]

      card = CardReviewer.answer_card(card, :again, time_now, config)

      assert card.card_type == :relearn
      assert card.current_step == 0
      assert card.due == ~U[2022-01-02 12:00:00Z]
      assert card.ease_factor == 2.3
      assert card.interval == Duration.parse!("P1D")
      assert card.lapses == 2
      assert card.reps == 4
    end
  end
end

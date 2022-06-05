defmodule Memorex.Cards.CardLogTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Repo
  alias Memorex.Cards.{Card, CardLog}
  alias Timex.Duration

  test "new/4" do
    answer_choice = :hard

    card_before = %Card{
      card_queue: :day_learn,
      card_type: :relearn,
      id: Ecto.UUID.generate(),
      interval: Duration.parse!("PT33S"),
      ease_factor: 2.5,
      due: ~U[2022-01-01 12:00:00Z]
    }

    card_after = %Card{
      card_queue: :learn,
      card_type: :review,
      interval: Duration.parse!("PT47S"),
      ease_factor: 2.4,
      due: ~U[2022-01-01 12:02:00Z]
    }

    time_to_answer = Duration.parse!("PT1M15S")

    card_log = CardLog.new(answer_choice, card_before, card_after, time_to_answer)

    assert card_log.answer_choice == answer_choice
    assert card_log.card_id == card_before.id
    assert card_log.time_to_answer == time_to_answer
    assert card_log.last_card_type == :relearn
    assert card_log.card_type == :review
    assert card_log.last_interval == Duration.parse!("PT33S")
    assert card_log.interval == Duration.parse!("PT47S")
    assert card_log.last_due == ~U[2022-01-01 12:00:00Z]
    assert card_log.due == ~U[2022-01-01 12:02:00Z]
    assert card_log.last_ease_factor == 2.5
    assert card_log.ease_factor == 2.4
  end

  test "Timex.Duration fields are stored in the database as ints" do
    card_log = %CardLog{card_type: :relearn, ease_factor: 2.5, interval: Duration.parse!("PT2S"), last_interval: Duration.parse!("PT3S")}
    card_log = %{card_log | time_to_answer: Duration.parse!("PT1M15S")}

    card_log = card_log |> Repo.insert!()

    assert card_log.time_to_answer == Duration.parse!("PT1M15S")
    assert card_log.interval == Duration.parse!("PT2S")
    assert card_log.last_interval == Duration.parse!("PT3S")
  end
end

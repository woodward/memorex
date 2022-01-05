defmodule Memorex.Schema.CardLogTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Schema.{Card, CardLog}

  test "new/4" do
    answer_choice = :hard
    card_before = %Card{card_queue: :day_learn, card_type: :relearn, id: Ecto.UUID.generate()}
    card_after = %Card{card_queue: :learn, card_type: :review}
    time_to_answer = Timex.Duration.parse!("PT1M15S")

    card_log = CardLog.new(answer_choice, card_before, card_after, time_to_answer)

    assert card_log.answer_choice == :hard
    assert card_log.card_id == card_before.id
    assert card_log.time_to_answer == Card.bracket_time_to_answer(time_to_answer)
    assert card_log.card_type == card_after.card_type

    # assert card_log.last_interval == card_before.last_interval
    # assert card_log.interval == card_after.interval
    # assert card_log.ease_factor == card_before.ease_factor
  end
end

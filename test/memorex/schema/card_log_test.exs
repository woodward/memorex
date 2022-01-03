defmodule Memorex.Schema.CardLogTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Schema.{Card, CardLog}

  test "new/4" do
    answer_choice = :hard
    card_before = %Card{}
    card_after = %Card{}
    time_to_answer = Timex.Duration.parse!("PT15S")

    card_log = CardLog.new(answer_choice, card_before, card_after, time_to_answer)

    assert card_log.answer_choice == :hard
  end
end

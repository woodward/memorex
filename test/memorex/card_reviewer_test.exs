defmodule Memorex.CardReviewerTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{CardReviewer, Config}
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
end

defmodule MemorexWeb.SharedViewHelpersTest do
  @moduledoc false

  use MemorexWeb.ConnCase, async: true
  alias Timex.Duration

  import MemorexWeb.SharedViewHelpers, only: [truncate: 1, truncate: 2, page_id: 1, format: 1]

  describe "truncate" do
    test "truncate" do
      assert truncate("Once upon a time in a world far far away") == "Once upon a time in a world..."
    end

    test "truncate with length option" do
      assert truncate("Once upon a time in a world far far away", length: 17) == "Once upon a ti..."
    end

    test "truncate with omission option" do
      assert truncate(
               "And they found that many people were sleeping better.",
               length: 25,
               omission: "... (continued)"
             ) == "And they f... (continued)"
    end

    test "truncate no applying" do
      assert truncate("Once upon a time in a world far far away", length: 50) == "Once upon a time in a world far far away"
    end

    test "truncate nil" do
      assert truncate(nil) == nil
    end

    test "truncate bool" do
      assert truncate(false) == false
    end
  end

  describe "page_id/1" do
    test "converts the view name into an ID" do
      assert Elixir.MemorexWeb.CardLive.Index |> page_id() == "card-live-index"
    end
  end

  describe "format" do
    test "returns a dash for a nil value" do
      assert format(nil) == "-"
    end

    test "returns the formatted interval" do
      assert format(Duration.parse!("PT33M")) == "33 minutes"
    end

    test "Keeps seconds if that's the only time present" do
      assert format(Duration.parse!("PT23S")) == "23 seconds"
    end

    test "Strips off seconds if other time values are present" do
      assert format(Duration.parse!("PT33M23S")) == "33 minutes"
    end

    test "Strips off milliseconds if other time values are present" do
      assert format(Duration.parse!("P9DT5H21M11.31125S")) == "1 week, 2 days, 5 hours, 21 minutes"
    end
  end
end

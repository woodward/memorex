defmodule MemorexWeb.SharedViewHelpersTest do
  @moduledoc false

  use MemorexWeb.ConnCase, async: true

  import MemorexWeb.SharedViewHelpers, only: [truncate: 1, truncate: 2, page_id: 1]

  describe "truncate" do
    # From: https://github.com/ikeikeikeike/phoenix_html_simplified_helpers/blob/master/test/phoenix_html_simplified_helpers/truncate_test.exs
    # but with the assertion orders swapped around

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

    test "truncate with separator option" do
      assert truncate("Once upon a time in a world far far away", length: 17, separator: " ") == "Once upon a..."
    end

    test "truncate with separator option one" do
      assert truncate("username@username-username.com", length: 20, separator: "user") == "username@..."
    end

    test "truncate with separator option two" do
      assert truncate(
               "username@username-username.comusername@username-username.com",
               separator: "user"
             ) == "username@username-..."
    end

    test "truncate with separator option three" do
      assert truncate(
               "username@username-username.comusername@username-username.com",
               length: 3,
               separator: "user"
             ) == "..."
    end
  end

  describe "page_id/1" do
    test "converts the view name into an ID" do
      assert Elixir.MemorexWeb.CardLive.Index |> page_id() == "card-live-index"
    end
  end
end

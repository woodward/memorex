defmodule Memorex.Scheduler.ConfigFileTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Scheduler.ConfigFile

  describe "read" do
    test "reads the config info from a TOML file" do
      config = ConfigFile.read("test/fixtures/deck_config.toml")

      assert config["new_cards_per_day"] == 35
      assert config["max_reviews_per_day"] == 350
      assert config["learn_ahead_time_interval"] == "PT20M"
    end

    test "the sample config file works" do
      config = ConfigFile.read("deck_config.example.toml")

      assert config["new_cards_per_day"] == 20
      assert config["max_reviews_per_day"] == 200
      assert config["learn_ahead_time_interval"] == "PT20M"
      assert config["learn_steps"] == ["PT1M", "PT10M"]
      assert config["relearn_steps"] == ["PT10M"]
      assert config["ease_minimum"] == 1.3
    end
  end
end

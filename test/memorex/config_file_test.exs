defmodule Memorex.ConfigFileTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.ConfigFile

  describe "read" do
    test "reads the config info from a TOML file" do
      config = ConfigFile.read("test/fixtures/deck_config.toml")

      assert config["new_cards_per_day"] == 35
      assert config["max_reviews_per_day"] == 350
      assert config["learn_ahead_time_interval"] == "PT20M"
    end
  end
end

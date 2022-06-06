defmodule Memorex.ConfigFileTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.ConfigFile

  describe "read" do
    test "reads the config info from a TOML file" do
      config = ConfigFile.read("test/fixtures/deck_config.toml")
      assert config["new_cards_per_day"] == 35
    end
  end
end

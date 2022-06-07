defmodule Memorex.ConfigTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{Config, Repo}
  alias Memorex.Cards.Deck
  alias Timex.Duration

  describe "to_config" do
    test "the config is merged with the standard config, and overrides values there" do
      config = %{new_cards_per_day: 40, learn_ahead_time_interval: "PT20M", learn_steps: ["PT15M", "PT21M"]}
      deck = %Deck{config: config} |> Repo.insert!()

      retrieved_deck = Repo.get!(Deck, deck.id)

      default_config = %Config{
        new_cards_per_day: 30,
        max_reviews_per_day: 200,
        graduating_interval_good: Duration.parse!("P2D"),
        relearn_steps: [Duration.parse!("PT17M")]
      }

      retrieved_deck_config = Config.to_config(retrieved_deck.config, default_config)

      assert retrieved_deck_config.new_cards_per_day == 40
      assert retrieved_deck_config.max_reviews_per_day == 200
      assert retrieved_deck_config.learn_ahead_time_interval == Duration.parse!("PT20M")
      assert retrieved_deck_config.graduating_interval_good == Duration.parse!("P2D")
      assert retrieved_deck_config.relearn_steps == [Duration.parse!("PT17M")]
      assert retrieved_deck_config.learn_steps == [Duration.parse!("PT15M"), Duration.parse!("PT21M")]
      assert retrieved_deck_config.__struct__ == Memorex.Config
    end
  end
end

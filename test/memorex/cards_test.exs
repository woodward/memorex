defmodule Memorex.CardsTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Cards
  alias Memorex.Cards.Card
  alias Timex.Duration

  describe "update_card!" do
    test "updates the card and also the due field" do
      old_due = ~U[2022-01-01 12:00:00Z]
      card = %Card{due: old_due, interval: Duration.parse!("P1D")}
      card = Repo.insert!(card)
      time_now = ~U[2022-02-01 12:00:00Z]

      updated_card = Cards.update_card!(card, %{interval: Duration.parse!("P10D")}, time_now)

      assert updated_card.due == ~U[2022-02-11 12:00:00Z]
      assert updated_card.interval == Duration.parse!("P10D")
    end
  end
end

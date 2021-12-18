defmodule Memorex.CardLog do
  @moduledoc false

  use Memorex.Schema
  alias Memorex.Card

  schema "card_logs" do
    # belongs_to :deck, Deck
    belongs_to :card, Card

    timestamps()
  end
end

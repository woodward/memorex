defmodule Memorex.CardLog do
  @moduledoc false

  use Memorex.Schema
  alias Memorex.Card

  @type t :: %__MODULE__{
          card_id: Ecto.UUID.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "card_logs" do
    # belongs_to :deck, Deck
    belongs_to :card, Card

    timestamps()
  end
end

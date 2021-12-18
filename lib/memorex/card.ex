defmodule Memorex.Card do
  @moduledoc false

  use Memorex.Schema
  alias Memorex.{CardLog, Note}

  schema "cards" do
    # belongs_to :deck, Deck
    belongs_to :note, Note
    has_many :card_logs, CardLog

    timestamps()
  end
end

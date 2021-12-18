defmodule Memorex.Deck do
  @moduledoc false

  use Memorex.Schema

  alias Memorex.Note

  schema "decks" do
    field :name, :binary

    has_many :notes, Note
    has_many :cards, through: [:notes, :cards]

    timestamps()
  end
end

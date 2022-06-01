defmodule Memorex.Cards.Deck do
  @moduledoc false

  use Memorex.Schema

  alias Memorex.Cards.Note

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          name: String.t(),
          #
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "decks" do
    field :name, :binary

    has_many :notes, Note
    has_many :cards, through: [:notes, :cards]

    timestamps()
  end
end

defmodule Memorex.Cards.Deck do
  @moduledoc false

  use Memorex.Schema

  alias Memorex.{Config, Schema}
  alias Memorex.Cards.Note
  alias Timex.Duration

  @type t :: %__MODULE__{
          id: Schema.id() | nil,
          name: String.t(),
          config: map(),
          #
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "decks" do
    field :name, :binary
    field :config, :map

    has_many :notes, Note
    has_many :cards, through: [:notes, :cards]

    timestamps()
  end
end

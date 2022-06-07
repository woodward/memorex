defmodule Memorex.Cards.Deck do
  @moduledoc false

  use Memorex.Schema
  import Ecto.Changeset

  alias Memorex.Schema
  alias Memorex.Cards.Note

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

  @spec changeset(Ecto.Changeset.t() | t(), map()) :: Ecto.Changeset.t()
  def changeset(deck, params \\ %{}) do
    deck |> cast(params, [:config])
  end
end

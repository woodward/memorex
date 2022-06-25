defmodule Memorex.Domain.Deck do
  @moduledoc """
  A `Memorex.Domain.Deck` contains `Memorex.Domain.Note`s  (which in turn can have one or two `Memorex.Domain.Card`s
  associated with them).  A `Memorex.Domain.Deck` can be read in from a single Markdown file (in which case the deck
  name is the name of the Markdown file, minus the .md extension) or from a directory which contains multiple Markdown
  files (in which case the deck name is the name of the directory containing the Markdown files).  A `Memorex.Domain.Deck`
  directory can also contain image file/text file pairs for "image notes"; see `Memorex.Domain.Note` for a description.

  `Memorex.Domain.Deck`s are re-read each time the mix task `memorex.read_notes` is run.

  """

  use Memorex.Ecto.Schema
  import Ecto.Changeset

  alias Memorex.Ecto.Schema
  alias Memorex.Domain.Note

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

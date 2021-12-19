defmodule Memorex.Deck do
  @moduledoc false

  use Memorex.Schema

  alias Memorex.{Note, Repo}

  schema "decks" do
    field :name, :binary

    has_many :notes, Note
    has_many :cards, through: [:notes, :cards]

    timestamps()
  end

  def read_file(filename, deck \\ nil) do
    filename
    |> File.read!()
    |> Note.parse_file_contents(deck)
  end

  def read_dir(dirname) do
    deck_name = Path.basename(dirname)
    deck = Repo.insert!(%__MODULE__{name: deck_name})

    Path.wildcard(dirname <> "/*.md")
    |> Enum.each(&read_file(&1, deck))
  end
end

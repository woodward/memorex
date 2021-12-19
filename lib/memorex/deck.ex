defmodule Memorex.Deck do
  @moduledoc false

  use Memorex.Schema

  alias Memorex.{Deck, Note, Repo}

  schema "decks" do
    field :name, :binary

    has_many :notes, Note
    has_many :cards, through: [:notes, :cards]

    timestamps()
  end

  def read_file(filename) do
    file_contents = File.read!(filename)
    name = Path.basename(filename, ".md")
    deck = Repo.insert!(%Deck{name: name})
    Note.parse_file_contents(file_contents, deck)
  end
end

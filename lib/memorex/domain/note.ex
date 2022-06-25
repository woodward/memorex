defmodule Memorex.Domain.Note do
  @moduledoc """
  There are two types of `Memorex.Domain.Note`s in `Memorex`.  The first type (called "text notes") consists of a single
  line in a `Memorex.Domain.Deck` Markdown file which contains either the bidirectional or unidirectional delimitter
  (which are by default "⮂" and "→", respectively).  The primary key of a text `Memorex.Domain.Note` is a UUID which is
  a hash of the note content (together with the note category, which is the name of the Markdown file if this deck is a
  directory which contains multple Markdown files).  Notes are flagged when the `Memorex.Deck` parsing starts (via
  `mix memorex.read_notes`), and any `Memorex.Domain.Note` which does not show up in the current parsing of the
  `Memorex.Domain.Deck` is purged (so if the `Memorex.Domain.Note` has been edited in the Markdown file, it will be
  deleted and re-created on the next reading/parsing of the `Memorex.Domain.Deck`).

  The second type of `Memorex.Domain.Note`s are "image notes".  An image file is placed in a `Memorex.Domain.Deck`
  directory on the filesystem.  A text file with the same name as the image file (but with the extension ".txt") is
  placed as a sibling to the image file.  The text file contains the answer to the image file.  The UUID for image notes
  is a hash of the contents of the image, the image file path, and the contents of the text file, so the UUID will
  change if the image file is changed, the file is moved, or the answer in the text file is changed.  Image notes can
  have the extensions ".jpg", ".jpeg", ".png", ".webp", ".svg", or ".gif".
  """

  use Memorex.Ecto.Schema

  alias Memorex.Ecto.Schema
  alias Memorex.Domain.{Card, Deck}

  @type t :: %__MODULE__{
          id: Schema.id() | nil,
          bidirectional?: boolean(),
          category: String.t() | nil,
          image_file_path: String.t() | nil,
          content: [String.t()],
          in_latest_parse?: boolean(),
          #
          deck_id: Schema.id() | nil,
          #
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "notes" do
    field :bidirectional?, :boolean
    field :category, :binary
    field :image_file_path, :binary
    field :content, {:array, :binary}
    field :in_latest_parse?, :boolean

    has_many :cards, Card
    belongs_to :deck, Deck

    timestamps()
  end

  @spec new(Keyword.t()) :: t()
  def new(opts \\ []) do
    category = Keyword.get(opts, :category)
    image_file_path = Keyword.get(opts, :image_file_path)
    image_file_content = Keyword.get(opts, :image_file_content)
    content = Keyword.get(opts, :content)
    deck = Keyword.get(opts, :deck)
    deck_id = if deck, do: deck.id, else: nil
    in_latest_parse? = Keyword.get(opts, :in_latest_parse?, true)
    bidirectional? = Keyword.get(opts, :bidirectional?, false)

    %__MODULE__{
      id: content_to_uuid(content, category, image_file_content, image_file_path),
      category: category,
      image_file_path: image_file_path,
      content: content,
      in_latest_parse?: in_latest_parse?,
      deck_id: deck_id,
      bidirectional?: bidirectional?
    }
  end

  @spec content_to_uuid([String.t()], String.t() | nil, binary() | nil, String.t() | nil) :: String.t()
  def content_to_uuid(content, category, image_file_content, image_file_path) do
    image_file_content = image_file_content || ""
    image_file_path = image_file_path || ""

    content
    |> Enum.reduce("#{category}", fn content_line, acc -> content_line <> acc end)
    |> Kernel.<>(image_file_content)
    |> Kernel.<>(image_file_path)
    |> sha1()
    |> sha1_to_uuid()
  end

  @spec sha1(String.t()) :: String.t()
  def sha1(string), do: :crypto.hash(:sha, string) |> Base.encode16() |> String.downcase()

  @spec sha1_to_uuid(String.t()) :: String.t()
  def sha1_to_uuid(sha), do: UUID.uuid5(nil, sha)
end

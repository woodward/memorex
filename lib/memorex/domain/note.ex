defmodule Memorex.Domain.Note do
  @moduledoc """
  A `Memorex.Domain.Note` is a single line in a `Memorex.Domain.Deck` Markdown file which contains either the
  bidirectional or unidirectional delimitter (which are by default "⮂" and "→", respectively).  The primary key of a
  `Memorex.Domain.Note` is a UUID which is a hash of the note content (together with the note category, which is the
  name of the Markdown file if this deck is a directory which contains multple Markdown files).  Notes are flagged when
  the `Memorex.Deck` parsing starts (via `mix memorex.read_notes`), and any `Memorex.Domain.Note` which does not show
  up in the current parsing of the `Memorex.Domain.Deck` is purged (so if the `Memorex.Domain.Note` has been edited in
  the Markdown file, it will be deleted and re-created on the next reading/parsing of the `Memorex.Domain.Deck`).
  """

  use Memorex.Ecto.Schema
  import Ecto.Changeset
  require Ecto.Query

  alias Memorex.Ecto.Repo
  alias Memorex.Ecto.Schema
  alias Memorex.Domain.{Card, Deck, Note}

  @type t :: %__MODULE__{
          id: Schema.id() | nil,
          bidirectional?: boolean(),
          category: String.t() | nil,
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
    field :content, {:array, :binary}
    field :in_latest_parse?, :boolean

    has_many :cards, Card
    belongs_to :deck, Deck

    timestamps()
  end

  @spec new(Keyword.t()) :: t()
  def new(opts \\ []) do
    category = Keyword.get(opts, :category)
    content = Keyword.get(opts, :content)
    deck = Keyword.get(opts, :deck)
    deck_id = if deck, do: deck.id, else: nil
    in_latest_parse? = Keyword.get(opts, :in_latest_parse?, true)
    bidirectional? = Keyword.get(opts, :bidirectional?, false)

    %__MODULE__{
      id: content_to_uuid(content, category),
      category: category,
      content: content,
      in_latest_parse?: in_latest_parse?,
      deck_id: deck_id,
      bidirectional?: bidirectional?
    }
  end

  @spec create_uuid_from_content(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def create_uuid_from_content(changeset) do
    content = changeset |> get_change(:content)
    category = changeset |> get_change(:category)

    changeset
    |> put_change(:id, content_to_uuid(content, category))
  end

  @spec content_to_uuid([String.t()], String.t() | nil) :: String.t()
  def content_to_uuid(content, category) do
    content
    |> Enum.reduce("#{category}", fn content_line, acc -> content_line <> acc end)
    |> sha1()
    |> sha1_to_uuid()
  end

  @spec sha1(String.t()) :: String.t()
  def sha1(string), do: :crypto.hash(:sha, string) |> Base.encode16() |> String.downcase()

  @spec sha1_to_uuid(String.t()) :: String.t()
  def sha1_to_uuid(sha), do: UUID.uuid5(nil, sha)

  @spec set_parse_flag(Note.t()) :: :ok
  def set_parse_flag(note), do: note |> Ecto.Changeset.change(in_latest_parse?: true) |> Repo.update!()

  @spec clear_parse_flags() :: :ok
  def clear_parse_flags, do: Repo.update_all(Note, set: [in_latest_parse?: false])

  @doc """
  Used to purge notes which are "orphaned" when reading in the Markdown file; that is, they have either been deleted
  from the Markdown file, or else their content has been edited (which causes their UUID to change).
  """
  @spec delete_notes_without_flag_set() :: :ok
  def delete_notes_without_flag_set do
    Ecto.Query.from(n in Note, where: n.in_latest_parse? == false) |> Repo.delete_all()
  end
end

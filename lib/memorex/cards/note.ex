defmodule Memorex.Cards.Note do
  @moduledoc false

  use Memorex.Schema
  import Ecto.Changeset
  require Ecto.Query

  alias Memorex.Repo
  alias Memorex.Cards.{Card, Deck, Note}

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          content: [String.t()],
          in_latest_parse?: boolean(),
          deck_id: Ecto.UUID.t() | nil,
          #
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "notes" do
    field :content, {:array, :binary}
    field :in_latest_parse?, :boolean

    has_many :cards, Card
    belongs_to :deck, Deck

    timestamps()
  end

  @spec new(Keyword.t()) :: t()
  def new(opts \\ []) do
    content = Keyword.get(opts, :content)
    deck = Keyword.get(opts, :deck)
    deck_id = if deck, do: deck.id, else: nil
    in_latest_parse? = Keyword.get(opts, :in_latest_parse?, true)
    %__MODULE__{id: content_to_uuid(content), content: content, in_latest_parse?: in_latest_parse?, deck_id: deck_id}
  end

  @spec create_uuid_from_content(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def create_uuid_from_content(changeset) do
    changeset
    |> put_change(:id, changeset |> get_change(:content) |> content_to_uuid())
  end

  @spec content_to_uuid([String.t()]) :: String.t()
  def content_to_uuid(content) do
    content
    |> Enum.reduce("", fn content_line, acc -> content_line <> acc end)
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

  @spec delete_notes_without_flag_set() :: :ok
  def delete_notes_without_flag_set do
    Ecto.Query.from(n in Note, where: n.in_latest_parse? == false) |> Repo.delete_all()
  end
end

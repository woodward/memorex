defmodule Memorex.Note do
  @moduledoc false

  use Memorex.Schema
  import Ecto.Changeset

  schema "notes" do
    field :content, {:array, :binary}

    timestamps()
  end

  def changeset(note, params \\ %{}) do
    note
    |> cast(params, [:content])
    |> create_uuid_from_content()
  end

  def create_uuid_from_content(changeset) do
    changeset
    |> put_change(:id, changeset |> get_change(:content) |> content_to_uuid())
  end

  def content_to_uuid(content) do
    content
    |> Enum.reduce("", fn content_line, acc -> content_line <> acc end)
    |> sha1()
    |> sha1_to_uuid()
  end

  def sha1(string), do: :crypto.hash(:sha, string) |> Base.encode16() |> String.downcase()

  def sha1_to_uuid(sha), do: UUID.uuid5(nil, sha)

  def parse_line(line) do
    content = line |> String.split(bidirectional_note_delimitter()) |> Enum.map(&String.trim(&1))
    %__MODULE__{} |> changeset(%{content: content})
  end

  def bidirectional_note_delimitter, do: Application.get_env(:memorex, Memorex.Note)[:bidirectional_note_delimitter]
end

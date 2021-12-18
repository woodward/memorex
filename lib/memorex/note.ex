defmodule Memorex.Note do
  @moduledoc false

  use Memorex.Schema
  import Ecto.Changeset
  require Ecto.Query

  alias Memorex.{Note, Repo}

  schema "notes" do
    field :content, {:array, :binary}
    field :in_latest_parse?, :boolean

    timestamps()
  end

  def new(opts \\ []) do
    content = Keyword.get(opts, :content)
    in_latest_parse? = Keyword.get(opts, :in_latest_parse?, true)
    %__MODULE__{id: content_to_uuid(content), content: content, in_latest_parse?: in_latest_parse?}
  end

  def parse_file_contents(contents) do
    Repo.update_all(Note, set: [in_latest_parse?: false])

    contents
    |> String.split("\n")
    |> Enum.each(fn line ->
      if String.match?(line, ~r/#{bidirectional_note_delimitter()}/) do
        note = line |> parse_line()
        note_from_db = Repo.get(Note, note.id)

        if note_from_db do
          note_from_db |> Ecto.Changeset.change(in_latest_parse?: true) |> Repo.update!()
        else
          Repo.insert!(note, on_conflict: :nothing)
        end
      end
    end)

    Ecto.Query.from(n in Note, where: n.in_latest_parse? == false) |> Repo.delete_all()
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
    new(content: content)
  end

  def bidirectional_note_delimitter, do: Application.get_env(:memorex, Memorex.Note)[:bidirectional_note_delimitter]
end

defmodule Memorex.Schema.Deck do
  @moduledoc false

  use Memorex.Schema

  alias Memorex.Repo
  alias Memorex.Schema.Note

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          name: String.t(),
          #
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

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

  def read_note_dirs(note_dirs \\ nil) do
    Note.clear_parse_flags()

    note_dirs = if note_dirs, do: note_dirs, else: Application.get_env(:memorex, Memorex.Note)[:note_dirs]

    note_dirs
    |> Enum.each(fn dir ->
      {:ok, files_and_dirs} = File.ls(dir)

      files_and_dirs
      |> Enum.map(fn file_or_dir ->
        pathname = Path.join(dir, file_or_dir)
        {:ok, file_stat} = File.stat(pathname)

        case file_stat.type do
          :regular ->
            deck = Repo.insert!(%__MODULE__{name: Path.rootname(file_or_dir)})
            read_file(pathname, deck)

          :directory ->
            read_dir(pathname)
        end
      end)
    end)

    Note.delete_notes_without_flag_set()
  end
end

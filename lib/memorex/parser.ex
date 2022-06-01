defmodule Memorex.Parser do
  @moduledoc false

  alias Memorex.{Decks, Repo}
  alias Memorex.Cards.{Card, Deck, Note}

  @spec read_file(String.t(), Deck.t() | nil) :: :ok
  def read_file(filename, deck \\ nil) do
    filename
    |> File.read!()
    |> parse_file_contents(deck)
  end

  @spec read_dir(String.t()) :: :ok
  def read_dir(dirname) do
    deck_name = Path.basename(dirname)
    deck = Decks.find_or_create!(deck_name)

    Path.wildcard(dirname <> "/*.md")
    |> Enum.each(&read_file(&1, deck))
  end

  @spec read_note_dirs([String.t()] | nil) :: :ok
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
            deck = Decks.find_or_create!(Path.rootname(file_or_dir))
            read_file(pathname, deck)

          :directory ->
            read_dir(pathname)
        end
      end)
    end)

    Note.delete_notes_without_flag_set()
  end

  @spec parse_file_contents(String.t(), Deck.t() | nil) :: :ok
  def parse_file_contents(contents, deck \\ nil) do
    contents
    |> String.split("\n")
    |> Enum.each(fn line ->
      if String.match?(line, ~r/#{bidirectional_note_delimitter()}/) do
        note = line |> parse_line()
        note_from_db = Repo.get(Note, note.id)

        if note_from_db do
          note_from_db |> Note.set_parse_flag()
        else
          %{note | deck: deck}
          |> Repo.insert!(on_conflict: :nothing)
          |> Card.create_bidirectional_from_note()
        end
      end
    end)
  end

  @spec parse_line(String.t()) :: Note.t()
  def parse_line(line) do
    content = line |> String.split(bidirectional_note_delimitter()) |> Enum.map(&String.trim(&1))
    Note.new(content: content)
  end

  @spec bidirectional_note_delimitter() :: String.t()
  def bidirectional_note_delimitter, do: Application.get_env(:memorex, Memorex.Note)[:bidirectional_note_delimitter]
end

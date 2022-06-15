defmodule Memorex.Parser do
  @moduledoc false

  alias Memorex.{Cards, Decks}
  alias Memorex.Scheduler.ConfigFile
  alias Memorex.Ecto.Repo
  alias Memorex.Domain.{Deck, Note}

  @spec read_file(String.t(), Keyword.t()) :: :ok
  def read_file(filename, opts \\ []) do
    filename
    |> File.read!()
    |> parse_file_contents(opts)
  end

  @spec read_dir(String.t()) :: :ok
  def read_dir(dirname) do
    deck =
      dirname
      |> Path.basename()
      |> Decks.find_or_create!()
      |> load_config_file_if_it_exists(Path.join(dirname, "deck_config.toml"))

    Path.wildcard(dirname <> "/*.md")
    |> Enum.each(fn filename ->
      category = Path.basename(filename, ".md")
      read_file(filename, deck: deck, category: category)
    end)
  end

  @spec read_note_dirs([String.t()] | nil) :: :ok
  def read_note_dirs(note_dirs \\ Application.get_env(:memorex, Memorex.Note)[:note_dirs]) do
    Note.clear_parse_flags()

    note_dirs
    |> Enum.each(fn dir ->
      {:ok, files_and_dirs} = File.ls(dir)

      files_and_dirs
      |> Enum.map(fn file_or_dir ->
        if does_not_start_with_dot(file_or_dir) do
          pathname = Path.join(dir, file_or_dir)
          {:ok, file_stat} = File.stat(pathname)

          case file_stat.type do
            :regular ->
              if Path.extname(file_or_dir) == ".md" do
                deck = Decks.find_or_create!(Path.rootname(file_or_dir))
                read_file(pathname, deck: deck)
                config_filename = Path.rootname(pathname) <> ".deck_config.toml"
                load_config_file_if_it_exists(deck, config_filename)
              end

            :directory ->
              read_dir(pathname)
          end
        end
      end)
    end)

    Note.delete_notes_without_flag_set()
  end

  @spec does_not_start_with_dot(String.t()) :: boolean()
  defp does_not_start_with_dot(file_or_dir), do: !String.starts_with?(file_or_dir, ".")

  @spec parse_file_contents(String.t(), Keyword.t()) :: :ok
  def parse_file_contents(contents, opts \\ []) do
    deck = Keyword.get(opts, :deck)
    category = Keyword.get(opts, :category)

    contents
    |> String.split("\n")
    |> Enum.each(fn line ->
      if is_note_line?(line) do
        note = parse_line(line, category)
        note_from_db = Repo.get(Note, note.id)

        if note_from_db do
          note_from_db |> Note.set_parse_flag()
        else
          %{note | deck: deck}
          |> Repo.insert!(on_conflict: :nothing)
          |> Cards.create_bidirectional_from_note()
        end
      end
    end)
  end

  @spec load_config_file_if_it_exists(Deck.t(), String.t()) :: Deck.t()
  defp load_config_file_if_it_exists(deck, config_filename) do
    if File.exists?(config_filename) do
      config_file = ConfigFile.read(config_filename)
      Decks.update_config(deck, config_file)
    else
      deck
    end
  end

  @spec is_note_line?(String.t()) :: boolean()
  def is_note_line?(line), do: String.match?(line, ~r/#{bidirectional_note_delimitter()}/)

  @spec parse_line(String.t(), String.t() | nil) :: Note.t()
  def parse_line(line, category) do
    content = line |> String.split(bidirectional_note_delimitter()) |> Enum.map(&String.trim(&1))
    Note.new(content: content, category: category)
  end

  @spec bidirectional_note_delimitter() :: String.t()
  def bidirectional_note_delimitter, do: Application.get_env(:memorex, Memorex.Note)[:bidirectional_note_delimitter]
end

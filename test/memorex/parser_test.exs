defmodule Memorex.ParserTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Cards.{Card, Deck, Note}
  alias Memorex.Parser

  describe "read_file" do
    test "a file gets converted into notes" do
      Parser.read_file("test/fixtures/deck1.md")

      assert Repo.all(Note) |> length() == 3
      assert Repo.all(Card) |> length() == 6
    end

    test "can take an optional deck" do
      deck = Repo.insert!(%Deck{name: "My Deck"})
      Parser.read_file("test/fixtures/deck1.md", deck)

      deck = Repo.all(Deck) |> Repo.preload(:notes) |> Repo.preload(:cards) |> List.first()

      assert deck.name == "My Deck"
      assert deck.notes |> length() == 3
      assert deck.cards |> length() == 6
    end
  end

  describe "read_dir" do
    test "all of the files in a directory get incorporated into the deck" do
      Parser.read_dir("test/fixtures/deck")

      deck = Repo.all(Deck) |> List.first()
      assert deck.name == "deck"

      [note1, note2] = Repo.all(Note, order_by: :id) |> Repo.preload(:deck)
      assert note1.deck.name == "deck"
      assert note2.deck.name == "deck"

      assert Repo.all(Card) |> length() == 4
    end
  end

  describe "read_multiple_dirs" do
    test "reads in notes from the multiple dirs in the config" do
      Parser.read_note_dirs()

      decks = Repo.all(Deck)
      deck_names = decks |> Enum.map(& &1.name) |> Enum.sort()
      assert deck_names == ["deck-1", "deck-2", "deck-3", "deck-4", "deck-5", "deck-6"]

      assert Repo.all(Note) |> length() == 13
      assert Repo.all(Card) |> length() == 26
    end

    test "does not create decks again if the directory is read a 2nd time" do
      Parser.read_note_dirs()
      assert Repo.all(Deck) |> length() == 6

      Parser.read_note_dirs()
      assert Repo.all(Deck) |> length() == 6
    end

    test "deletes notes that are no longer present in the files" do
      notes_dir = "test/tmp"
      File.mkdir(notes_dir)
      filename = "notes.md"
      notes_file = Path.join(notes_dir, filename)

      file_contents = """
      one ⮂ 1
      """

      File.write!(notes_file, file_contents)

      Parser.read_note_dirs([notes_dir])
      assert Repo.all(Note) |> length() == 1

      edited_file_contents = """
      one ⮂ edited
      """

      File.write!(notes_file, edited_file_contents)

      Parser.read_note_dirs([notes_dir])
      assert Repo.all(Note) |> length() == 1
    end
  end

  test "parse_line/1" do
    line = " one ⮂   two  "
    note = Parser.parse_line(line)
    assert note == %Note{content: ["one", "two"], id: "b6db891e-d142-51fa-9e0a-7100b0843d78", in_latest_parse?: true}
  end

  describe "parse_file_contents/1" do
    test "reads in the note contents" do
      assert Repo.all(Note) |> length() == 0

      file_contents = """
      one ⮂   two

      three ⮂   four

      something else

      five ⮂   six

      """

      Parser.parse_file_contents(file_contents)

      assert Repo.all(Note) |> length() == 3
      assert Repo.all(Card) |> length() == 6
    end

    test "can read in existing notes" do
      assert Repo.all(Note) |> length() == 0

      file_contents = """
      one ⮂  one
      """

      Parser.parse_file_contents(file_contents)

      all_notes = Repo.all(Note)
      assert length(all_notes) == 1

      Parser.parse_file_contents(file_contents)

      assert Repo.all(Note) |> length() == 1
      assert Repo.all(Card) |> length() == 2
    end

    test "associates a deck with the notes if one is provided" do
      assert Repo.all(Note) |> length() == 0
      deck = Repo.insert!(%Deck{name: "My Deck"})

      file_contents = """
      one ⮂ one
      """

      Parser.parse_file_contents(file_contents, deck)

      note = Repo.all(Note) |> Repo.preload(:deck) |> List.first()
      assert note.deck.id == deck.id
      assert note.deck.name == "My Deck"
    end
  end
end

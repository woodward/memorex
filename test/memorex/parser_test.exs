defmodule Memorex.ParserTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Domain.{Card, Deck, Note}
  alias Memorex.Parser

  describe "read_file" do
    test "a file gets converted into notes" do
      Parser.read_file("test/fixtures/deck1.md")

      assert Repo.all(Note) |> length() == 3
      assert Repo.all(Card) |> length() == 6
    end

    test "can take an optional deck" do
      deck = Repo.insert!(%Deck{name: "My Deck"})
      Parser.read_file("test/fixtures/deck1.md", deck: deck)

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

      assert note1.category == "file1"
      assert note2.category == "file2"

      assert Repo.all(Card) |> length() == 4
    end
  end

  describe "read_multiple_dirs" do
    test "reads in notes from the multiple dirs in the config excluding filenames that start with a dot" do
      Parser.read_note_dirs()

      decks = Repo.all(Deck)
      deck_names = decks |> Enum.map(& &1.name) |> Enum.sort()
      assert deck_names == ["deck-1", "deck-2", "deck-3", "deck-4", "deck-5", "deck-6"]

      assert Repo.all(Note) |> length() == 13
      assert Repo.all(Card) |> length() == 26

      decks_without_configs = ["deck-1", "deck-2", "deck-3", "deck-5"]

      decks_without_configs
      |> Enum.each(fn deck_name ->
        deck = Repo.get_by(Deck, name: deck_name)
        assert deck.config == %{}
      end)

      deck_4 = Repo.get_by(Deck, name: "deck-4")
      assert deck_4.config == %{"new_cards_per_day" => 67}

      deck_6 = Repo.get_by(Deck, name: "deck-6")
      assert deck_6.config == %{"new_cards_per_day" => 33}
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

  describe "parse_line/1" do
    test "parse_line/1 works for the bidirectional note" do
      line = " one ⮂   two  "
      category = "my category"
      note = Parser.parse_line(line, category)

      assert note == %Note{
               content: ["one", "two"],
               category: "my category",
               id: "99f1f73a-69be-5588-a86b-de7b3163d575",
               in_latest_parse?: true,
               bidirectional?: true
             }
    end
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

      Parser.parse_file_contents(file_contents, deck: deck)

      note = Repo.all(Note) |> Repo.preload(:deck) |> List.first()
      assert note.deck.id == deck.id
      assert note.deck.name == "My Deck"
    end
  end

  describe "is_note_line?/1" do
    test "returns true if the line contains the note character" do
      line = "Blah blah ⮂ foo foo"
      assert Parser.is_note_line?(line) == true
    end

    test "returns false if the line does not contain the note character" do
      line = "Blah blah foo foo"
      assert Parser.is_note_line?(line) == false
    end
  end

  describe "read_toml_deck_config" do
    test "reads the config info from a TOML file" do
      config = Parser.read_toml_deck_config("test/fixtures/deck_config.toml")

      assert config["new_cards_per_day"] == 35
      assert config["max_reviews_per_day"] == 350
      assert config["learn_ahead_time_interval"] == "PT20M"
    end

    test "the sample config file works (which contains all of the possible values)" do
      config = Parser.read_toml_deck_config("deck_config.example.toml")

      assert config["new_cards_per_day"] == 20
      assert config["max_reviews_per_day"] == 200
      assert config["learn_ahead_time_interval"] == "PT20M"
      assert config["learn_steps"] == ["PT1M", "PT10M"]
      assert config["relearn_steps"] == ["PT10M"]
      assert config["ease_minimum"] == 1.3
    end
  end
end

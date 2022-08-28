defmodule Memorex.ParserTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Domain.{Card, Deck, Note}
  alias Memorex.{Cards, Parser}

  describe "read_notes_file" do
    test "a file gets converted into notes" do
      Parser.read_notes_file("test/fixtures/deck1.md")

      assert Repo.all(Note) |> length() == 3
      assert Repo.all(Card) |> length() == 6
    end

    test "can take an optional deck" do
      deck = Repo.insert!(%Deck{name: "My Deck"})
      opts = [deck: deck] |> Keyword.merge(Parser.default_opts())
      Parser.read_notes_file("test/fixtures/deck1.md", opts)

      deck = Repo.all(Deck) |> Repo.preload(:notes) |> Repo.preload(:cards) |> List.first()

      assert deck.name == "My Deck"
      assert deck.notes |> length() == 3
      assert deck.cards |> length() == 6
    end
  end

  describe "read_image_note" do
    test "a file gets converted into notes" do
      deck = %Deck{name: "deck_with_different_image_types"} |> Repo.insert!()
      Parser.read_image_note("test/fixtures/deck_with_different_image_types/goldfish.webp", deck: deck)

      assert Repo.all(Note) |> length() == 1
      assert Repo.all(Card) |> length() == 1

      [note] = Repo.all(Note)

      assert note.image_file_path == "/images/decks/deck_with_different_image_types/goldfish.webp"
      assert note.id == "f701b5fe-f852-57ec-9e45-ad3ea7c3c250"
      assert note.content == ["A goldfish"]
      lstat = File.lstat!(File.cwd!() <> "/priv/static" <> note.image_file_path)
      assert lstat.type == :symlink
    end

    test "does not do anything if there is no text file to go along with the image file" do
      deck = %Deck{name: "deck_with_different_image_types"} |> Repo.insert!()
      Parser.read_image_note("test/fixtures/deck_with_different_image_types/image-without-corresponding-text-file.jpeg", deck: deck)

      assert Repo.all(Note) |> length() == 0
      assert Repo.all(Card) |> length() == 0
    end

    test "multiple images for one text file" do
      deck = %Deck{name: "deck_with_multiple_images_for_one_text_file"} |> Repo.insert!()
      Parser.read_image_note("test/fixtures/deck_with_multiple_images_for_one_text_file/goldfish - 27.jpeg", deck: deck)

      assert Repo.all(Note) |> length() == 1
      assert Repo.all(Card) |> length() == 1

      [note] = Repo.all(Note)

      assert note.image_file_path == "/images/decks/deck_with_multiple_images_for_one_text_file/goldfish - 27.jpeg"
      assert note.id == "9f9c0f2b-f475-5b39-92b7-300aeb64a86c"
      assert note.content == ["A goldfish"]
      lstat = File.lstat!(File.cwd!() <> "/priv/static" <> note.image_file_path)
      assert lstat.type == :symlink
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

      assert note1.category == ["file1"]
      assert note2.category == ["file2"]

      assert Repo.all(Card) |> length() == 4
    end

    test "all of the image files in a directory get incorporated into the deck" do
      Parser.read_dir("test/fixtures/deck_with_different_image_types")

      deck = Repo.all(Deck) |> List.first()
      assert deck.name == "deck_with_different_image_types"

      assert Repo.all(Note) |> length() == 6

      Repo.all(Note, order_by: :id)
      |> Repo.preload(:deck)
      |> Enum.each(fn note ->
        assert note.deck.name == "deck_with_different_image_types"
      end)

      assert Repo.all(Card) |> length() == 6
    end

    test "recursively reads directories, creating categories & subcategories for the notes" do
      Parser.read_dir("test/fixtures/deck_with_nested_categories")

      all_decks = Repo.all(Deck)
      assert length(all_decks) == 1
      [deck] = all_decks
      assert deck.name == "deck_with_nested_categories"

      assert Repo.all(Note) |> length() == 6

      all_notes = Repo.all(Note, order_by: :id)

      all_notes
      |> Repo.preload(:deck)
      |> Enum.each(fn note ->
        assert note.deck.name == "deck_with_nested_categories"
      end)

      all_cards = Repo.all(Card) |> Repo.preload([:note])
      assert length(all_cards) == 9

      # ----------------
      text_notes = all_notes |> Enum.reject(& &1.image_file_path)

      [text_note_one_category] = text_notes |> Enum.filter(&(&1.content == ["A", "a"]))
      assert text_note_one_category.category == ["category-1"]

      [text_note_two_subcategories] = text_notes |> Enum.filter(&(&1.content == ["B", "b"]))
      assert text_note_two_subcategories.category == ["subcategory-1", "subcategory-2"]

      [text_note_three_subcategories] = text_notes |> Enum.filter(&(&1.content == ["C", "c"]))
      assert text_note_three_subcategories.category == ["subcategory-1", "subcategory-2", "subcategory-3"]

      # ----------------
      image_notes = all_notes |> Enum.filter(& &1.image_file_path)

      [image_note_no_category] = image_notes |> Enum.filter(&(&1.content == ["Fish - no category"]))
      assert image_note_no_category.category == []

      [image_note_one_category] = image_notes |> Enum.filter(&(&1.content == ["Fish with one subcategory"]))
      assert image_note_one_category.category == ["subcategory-1"]

      [image_note_two_categories] = image_notes |> Enum.filter(&(&1.content == ["Fish with two subcategories"]))
      assert image_note_two_categories.category == ["subcategory-1", "subcategory-2"]
    end
  end

  describe "read_multiple_dirs" do
    test "reads in notes from the multiple dirs in the config excluding filenames that start with a dot" do
      Parser.read_note_dirs()

      decks = Repo.all(Deck)
      deck_names = decks |> Enum.map(& &1.name) |> Enum.sort()
      assert deck_names == ["deck-1", "deck-2", "deck-3", "deck-4", "deck-5", "deck-6", "deck-7-images"]

      assert Repo.all(Note) |> length() == 14
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

      deck_7 = Repo.get_by(Deck, name: "deck-7-images")
      cards_for_deck_7 = Cards.cards_for_deck(deck_7.id) |> Repo.all() |> Repo.preload([:note])
      assert length(cards_for_deck_7) == 1
      [card] = cards_for_deck_7
      assert card.note.content == ["Bass"]
      assert card.note.image_file_path == "/images/decks/deck-7-images/fish.jpg"
      lstat = File.lstat!(File.cwd!() <> "/priv/static" <> card.note.image_file_path)
      assert lstat.type == :symlink
    end

    test "does not create decks again if the directory is read a 2nd time" do
      Parser.read_note_dirs()
      assert Repo.all(Deck) |> length() == 7

      Parser.read_note_dirs()
      assert Repo.all(Deck) |> length() == 7
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
      opts = [category: ["my category"]] |> Keyword.merge(Parser.default_opts())
      note = Parser.parse_line(line, opts)

      assert note == %Note{
               content: ["one", "two"],
               category: ["my category"],
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

      Parser.parse_file_contents(file_contents, Parser.default_opts())

      assert Repo.all(Note) |> length() == 3
      assert Repo.all(Card) |> length() == 6
    end

    test "can read in existing notes" do
      assert Repo.all(Note) |> length() == 0

      file_contents = """
      one ⮂  one
      """

      Parser.parse_file_contents(file_contents, Parser.default_opts())

      all_notes = Repo.all(Note)
      assert length(all_notes) == 1

      Parser.parse_file_contents(file_contents, Parser.default_opts())

      assert Repo.all(Note) |> length() == 1
      assert Repo.all(Card) |> length() == 2
    end

    test "associates a deck with the notes if one is provided" do
      assert Repo.all(Note) |> length() == 0
      deck = Repo.insert!(%Deck{name: "My Deck"})

      file_contents = """
      one ⮂ one
      """

      opts = [deck: deck] |> Keyword.merge(Parser.default_opts())
      Parser.parse_file_contents(file_contents, opts)

      note = Repo.all(Note) |> Repo.preload(:deck) |> List.first()
      assert note.deck.id == deck.id
      assert note.deck.name == "My Deck"
    end
  end

  describe "is_note_line?/1" do
    test "returns true if the line contains the bidirectional note character" do
      line = "Blah blah ⮂ foo foo"
      assert Parser.is_note_line?(line, Parser.default_opts()) == true
    end

    test "returns false if the line does not contain the note character" do
      line = "Blah blah foo foo"
      assert Parser.is_note_line?(line, Parser.default_opts()) == false
    end

    test "returns true if the line contains the unidirectional note character" do
      line = "Blah blah → foo foo"
      assert Parser.is_note_line?(line, Parser.default_opts()) == true
    end
  end

  describe "is_bidirectional_note?/1" do
    test "returns true if the line contains the bidirectional note character" do
      line = "Blah blah ⮂ foo foo"
      assert Parser.is_bidirectional_note?(line, bidirectional_note_delimitter: "⮂") == true
    end

    test "returns false if the line contains the unidirectional note character" do
      line = "Blah blah → foo foo"
      assert Parser.is_bidirectional_note?(line, bidirectional_note_delimitter: "⮂") == false
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

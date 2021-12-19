defmodule Memorex.NoteTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{Card, CardLog, Deck, Note, Repo}

  # From: https://stackoverflow.com/questions/136505/searching-for-uuids-in-text-with-regex
  @uuid_regex ~r/\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b/

  test "has a UUID primary key and an array of content" do
    Repo.insert(%Note{content: ["zero", "one"]})
    note = Repo.all(Note) |> List.first()

    assert String.match?(note.id, @uuid_regex)

    [content0, content1] = note.content
    assert content0 == "zero"
    assert content1 == "one"
  end

  test "a note can have a specified UUID on creation" do
    uuid = "a6c86ddf-3ff9-4995-9f04-77c9dcb2848e"
    Repo.insert(%Note{id: uuid})
    note = Repo.all(Note) |> List.first()
    assert note.id == uuid
  end

  test "the note's UUID is based on its content" do
    Note.new(content: ["zero", "one"]) |> Repo.insert()
    note = Repo.all(Note) |> List.first()

    assert note.id == "78e531f9-e629-5e9a-b474-3272beaf39bf"

    [content0, content1] = note.content
    assert content0 == "zero"
    assert content1 == "one"
  end

  test "content_to_uuid/1" do
    content1 = ["zero", "one", "two"]
    uid1 = Note.content_to_uuid(content1)
    assert uid1 == "cd04855f-1ef3-54e0-9d1c-1e8ea24563c2"

    content2 = ["0", "one", "two"]
    uid2 = Note.content_to_uuid(content2)
    assert uid2 == "e4bdc36d-f397-5cc2-a60a-87003946c04a"
    assert uid1 != uid2
  end

  test "sha1 of some content" do
    assert Note.sha1("some content") == "94e66df8cd09d410c62d9e0dc59d3a884e458e05"
  end

  test "sha1_to_uuid/1" do
    sha = "94e66df8cd09d410c62d9e0dc59d3a884e458e05"
    assert Note.sha1_to_uuid(sha) == "950db789-4f02-593f-a046-5fdc94d0cdaf"
  end

  test "parse_line/1" do
    line = " one ⮂   two  "
    note = Note.parse_line(line)
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

      Note.parse_file_contents(file_contents)

      assert Repo.all(Note) |> length() == 3
      assert Repo.all(Card) |> length() == 6
    end

    test "can read in existing notes" do
      assert Repo.all(Note) |> length() == 0

      file_contents = """
      one ⮂  one
      """

      Note.parse_file_contents(file_contents)

      all_notes = Repo.all(Note)
      assert length(all_notes) == 1

      Note.parse_file_contents(file_contents)

      assert Repo.all(Note) |> length() == 1
      assert Repo.all(Card) |> length() == 2
    end

    test "associates a deck with the notes if one is provided" do
      assert Repo.all(Note) |> length() == 0
      deck = Repo.insert!(%Deck{name: "My Deck"})

      file_contents = """
      one ⮂ one
      """

      Note.parse_file_contents(file_contents, deck)

      note = Repo.all(Note) |> Repo.preload(:deck) |> List.first()
      assert note.deck.id == deck.id
      assert note.deck.name == "My Deck"
    end
  end

  describe ":in_latest_parse? flag operations" do
    test "deletes notes that are no longer present and leaves existing notes" do
      assert Repo.all(Note) |> length() == 0

      file_contents = """
      one ⮂ one
      two ⮂ two
      """

      Note.parse_file_contents(file_contents)

      assert Repo.all(Note) |> length() == 2
      assert Repo.all(Card) |> length() == 4

      new_file_contents = """
      one ⮂ one
      2 ⮂ 2
      """

      Note.set_parse_flag()
      Note.parse_file_contents(new_file_contents)
      Note.delete_notes_without_flag_set()

      assert Repo.all(Note) |> length() == 2
      assert Repo.all(Card) |> length() == 4
    end
  end

  test "deletes notes, cards, and card logs when deleted" do
    note = Repo.insert!(%Note{})
    card = Repo.insert!(%Card{note: note})
    card_log = Repo.insert!(%CardLog{card: card})

    Repo.delete!(note)

    assert Repo.get(Card, card.id) == nil
    assert Repo.get(CardLog, card_log.id) == nil

    assert Repo.all(Note) |> length() == 0
    assert Repo.all(Card) |> length() == 0
  end
end

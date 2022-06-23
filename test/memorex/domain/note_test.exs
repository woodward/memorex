defmodule Memorex.Domain.NoteTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.Parser
  alias Memorex.Ecto.Repo
  alias Memorex.Domain.{Card, CardLog, Note}
  alias Timex.Duration

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

  test "the note's UUID is based on its content and category" do
    Note.new(content: ["zero", "one"], category: "some category") |> Repo.insert()
    note = Repo.all(Note) |> List.first()

    assert note.id == "5fbaa83b-e42d-5588-a1c1-09056e1bad2d"

    [content0, content1] = note.content
    assert content0 == "zero"
    assert content1 == "one"
  end

  test "the note's UUID is based on its the image file path and content and category" do
    Note.new(image_file_content: "some-bytes", image_file_path: "/foo/bar", content: ["zero"], category: "some category") |> Repo.insert()
    note = Repo.all(Note) |> List.first()

    assert note.id == "ecf9a165-7cca-56f4-8b7b-0c079dd91653"

    [content0] = note.content
    assert content0 == "zero"
    assert note.image_file_path == "/foo/bar"
  end

  test "the note's UUID is does not blow up if the category is nil" do
    Note.new(content: ["zero", "one"]) |> Repo.insert()
    note = Repo.all(Note) |> List.first()

    assert note.id == "78e531f9-e629-5e9a-b474-3272beaf39bf"

    [content0, content1] = note.content
    assert content0 == "zero"
    assert content1 == "one"
  end

  describe "content_to_uuid/2" do
    test "content_to_uuid/2" do
      content1 = ["zero", "one", "two"]
      uid1 = Note.content_to_uuid(content1, "category", nil, nil)
      assert uid1 == "82208bd0-1c9f-5b0a-95f5-1330874e26f8"

      content2 = ["0", "one", "two"]
      uid2 = Note.content_to_uuid(content2, "category", nil, nil)
      assert uid2 == "be112558-ee18-54cb-beb7-2133a3d5f769"
      assert uid1 != uid2
    end

    test "does not blow up if the category is nil" do
      content1 = ["zero", "one", "two"]
      uid1 = Note.content_to_uuid(content1, nil, nil, nil)
      assert uid1 == "cd04855f-1ef3-54e0-9d1c-1e8ea24563c2"
    end

    test "uses the image file path and content if they are present" do
      content1 = ["zero", "one", "two"]
      uid1 = Note.content_to_uuid(content1, "category", "image-bytes", "/path/to/image-file.jpg")
      assert uid1 == "fdfb1fa4-50f2-5cb6-b519-a72adc46ff90"
    end
  end

  test "sha1 of some content" do
    assert Note.sha1("some content") == "94e66df8cd09d410c62d9e0dc59d3a884e458e05"
  end

  test "sha1_to_uuid/1" do
    sha = "94e66df8cd09d410c62d9e0dc59d3a884e458e05"
    assert Note.sha1_to_uuid(sha) == "950db789-4f02-593f-a046-5fdc94d0cdaf"
  end

  describe ":in_latest_parse? flag operations" do
    test "deletes notes that are no longer present and leaves existing notes" do
      assert Repo.all(Note) |> length() == 0

      file_contents = """
      one ⮂ one
      two ⮂ two
      """

      Parser.parse_file_contents(file_contents, Parser.default_opts())

      assert Repo.all(Note) |> length() == 2
      assert Repo.all(Card) |> length() == 4

      new_file_contents = """
      one ⮂ one
      2 ⮂ 2
      """

      Note.clear_parse_flags()
      Parser.parse_file_contents(new_file_contents, Parser.default_opts())
      Note.delete_notes_without_flag_set()

      assert Repo.all(Note) |> length() == 2
      assert Repo.all(Card) |> length() == 4
    end
  end

  test "deletes notes, cards, and card logs when deleted" do
    note = Repo.insert!(%Note{})
    card = Repo.insert!(%Card{note: note})

    card_log =
      Repo.insert!(%CardLog{
        card: card,
        ease_factor: 2.5,
        interval: Duration.parse!("PT1S"),
        last_interval: Duration.parse!("PT1S"),
        time_to_answer: Duration.parse!("PT1S")
      })

    Repo.delete!(note)

    assert Repo.get(Card, card.id) == nil
    assert Repo.get(CardLog, card_log.id) == nil

    assert Repo.all(Note) |> length() == 0
    assert Repo.all(Card) |> length() == 0
  end
end

defmodule Memorex.Domain.NoteTest do
  @moduledoc false
  use Memorex.DataCase

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
    Note.new(content: ["zero", "one"], category: ["some category", "some deeper category"]) |> Repo.insert()
    note = Repo.all(Note) |> List.first()

    assert note.id == "edc40dcf-9232-540a-ad80-644d4b7b5b01"

    [content0, content1] = note.content
    assert content0 == "zero"
    assert content1 == "one"
  end

  test "the note's UUID is based on its the image file path and content and category" do
    Note.new(
      image_file_content: "some-bytes",
      image_file_path: "/foo/bar",
      content: ["zero"],
      category: ["some category", "some deeper category"]
    )
    |> Repo.insert()

    note = Repo.all(Note) |> List.first()

    assert note.id == "1ed80628-82c2-59df-b440-2945d1d4aeaf"

    [content0] = note.content
    assert content0 == "zero"
    assert note.image_file_path == "/foo/bar"
  end

  test "the note's UUID is does not blow up if the category is nil" do
    Note.new(content: ["zero", "one"], category: []) |> Repo.insert()
    note = Repo.all(Note) |> List.first()

    assert note.id == "78e531f9-e629-5e9a-b474-3272beaf39bf"

    [content0, content1] = note.content
    assert content0 == "zero"
    assert content1 == "one"
  end

  describe "content_to_uuid/2" do
    test "content_to_uuid/2" do
      content1 = ["zero", "one", "two"]
      uid1 = Note.content_to_uuid(content1, ["category", "subcategory"], nil, nil)
      assert uid1 == "c8edf54e-9b73-5e87-978d-7a43ca186c40"

      content2 = ["0", "one", "two"]
      uid2 = Note.content_to_uuid(content2, ["category", "subcategory"], nil, nil)
      assert uid2 == "f06fcad6-77d2-549f-b6e5-047a8c32072b"
      assert uid1 != uid2
    end

    test "does not blow up if the category is an empty array" do
      content1 = ["zero", "one", "two"]
      uid1 = Note.content_to_uuid(content1, [], nil, nil)
      assert uid1 == "cd04855f-1ef3-54e0-9d1c-1e8ea24563c2"
    end

    test "uses the image file path and content if they are present" do
      content1 = ["zero", "one", "two"]
      uid1 = Note.content_to_uuid(content1, ["category", "subcategory"], "image-bytes", "/path/to/image-file.jpg")
      assert uid1 == "c229fa2c-4bc3-5c14-915d-df000f9ac9e8"
    end
  end

  test "sha1 of some content" do
    assert Note.sha1("some content") == "94e66df8cd09d410c62d9e0dc59d3a884e458e05"
  end

  test "sha1_to_uuid/1" do
    sha = "94e66df8cd09d410c62d9e0dc59d3a884e458e05"
    assert Note.sha1_to_uuid(sha) == "950db789-4f02-593f-a046-5fdc94d0cdaf"
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

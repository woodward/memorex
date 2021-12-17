defmodule Memorex.NoteTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{Note, Repo}

  # From: https://stackoverflow.com/questions/136505/searching-for-uuids-in-text-with-regex
  @uuid_regex ~r/\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b/

  test "has UUID primary keys and an array of content" do
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
    Note.changeset(%Note{}, %{"content" => ["zero", "one"]}) |> Repo.insert()
    note = Repo.all(Note) |> List.first()

    assert note.id == "78e531f9-e629-5e9a-b474-3272beaf39bf"

    [content0, content1] = note.content
    assert content0 == "zero"
    assert content1 == "one"
  end

  test "content to uuid" do
    content_1 = ["zero", "one", "two"]
    uid_1 = Note.content_to_uuid(content_1)
    assert uid_1 == "cd04855f-1ef3-54e0-9d1c-1e8ea24563c2"

    content_2 = ["0", "one", "two"]
    uid_2 = Note.content_to_uuid(content_2)
    assert uid_2 == "e4bdc36d-f397-5cc2-a60a-87003946c04a"
    assert uid_1 != uid_2
  end

  test "sha1 of some content" do
    assert Note.sha1("some content") == "94e66df8cd09d410c62d9e0dc59d3a884e458e05"
  end

  test "sha1_to_uuid/1" do
    sha = "94e66df8cd09d410c62d9e0dc59d3a884e458e05"
    assert Note.sha1_to_uuid(sha) == "950db789-4f02-593f-a046-5fdc94d0cdaf"
  end
end

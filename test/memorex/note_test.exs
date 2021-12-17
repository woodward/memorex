defmodule Memorex.NoteTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{Note, Repo}

  # From: https://stackoverflow.com/questions/136505/searching-for-uuids-in-text-with-regex
  @uuid_regex ~r/\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b/

  test "has UUID primary keys and an array of content" do
    Repo.insert(%Note{contents: ["zero", "one"]})
    note = Repo.all(Note) |> List.first()

    assert String.match?(note.uuid, @uuid_regex)
    [content0, content1] = note.contents
    assert content0 == "zero"
    assert content1 == "one"
  end
end

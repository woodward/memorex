defmodule Memorex.NotesTest do
  @moduledoc false
  use Memorex.DataCase

  alias Memorex.{Notes, Parser}
  alias Memorex.Ecto.Repo
  alias Memorex.Domain.{Card, Note}

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

      Notes.clear_parse_flags()
      Parser.parse_file_contents(new_file_contents, Parser.default_opts())
      Notes.delete_notes_without_flag_set()

      assert Repo.all(Note) |> length() == 2
      assert Repo.all(Card) |> length() == 4
    end
  end
end

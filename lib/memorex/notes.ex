defmodule Memorex.Notes do
  @moduledoc """
  Functions for interacting with `Memorex.Domain.Notes`s.
  """

  require Ecto.Query

  alias Memorex.Domain.Note
  alias Memorex.Ecto.Repo

  @spec set_parse_flag(Note.t()) :: :ok
  def set_parse_flag(note), do: note |> Ecto.Changeset.change(in_latest_parse?: true) |> Repo.update!()

  @spec clear_parse_flags() :: :ok
  def clear_parse_flags, do: Repo.update_all(Note, set: [in_latest_parse?: false])

  @doc """
  Used to purge notes which are "orphaned" when reading in the Markdown file; that is, they have either been deleted
  from the Markdown file, or else their content has been edited (which causes their UUID to change).
  """
  @spec delete_notes_without_flag_set() :: :ok
  def delete_notes_without_flag_set do
    Ecto.Query.from(n in Note, where: n.in_latest_parse? == false) |> Repo.delete_all()
  end
end

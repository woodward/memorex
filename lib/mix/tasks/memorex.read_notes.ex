defmodule Mix.Tasks.Memorex.ReadNotes do
  @moduledoc """
  Reads the notes from the notes dirs

  ```bash
  $ mix memorex.read_notes
  ```
  """

  alias Memorex.Schema.Deck

  @shortdoc "Reads the notes from the notes dirs"
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    Deck.read_note_dirs()
  end
end

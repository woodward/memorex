defmodule Mix.Tasks.Memorex.ReadNotes do
  @moduledoc """
  Reads the notes from the notes dirs

  ```bash
  $ mix memorex.read_notes
  ```
  """

  @shortdoc "Reads the notes from the notes dirs"
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    Memorex.Schema.Deck.read_note_dirs()
  end
end

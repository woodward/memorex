defmodule Memorex.Card do
  @moduledoc false

  use Memorex.Schema
  alias Memorex.{CardLog, Note, Repo}

  schema "cards" do
    field :note_question_index, :integer
    field :note_answer_index, :integer

    # belongs_to :deck, Deck
    belongs_to :note, Note
    has_many :card_logs, CardLog

    timestamps()
  end

  def create_bidirectional_from_note(note) do
    card1 = %__MODULE__{note: note, note_question_index: 0, note_answer_index: 1}
    card2 = %__MODULE__{note: note, note_question_index: 1, note_answer_index: 0}
    Repo.insert!(card1)
    Repo.insert!(card2)
  end
end

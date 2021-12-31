defmodule Memorex.Schema.Card do
  @moduledoc false

  use Memorex.Schema
  alias Memorex.Schema.{CardLog, Note}
  alias Memorex.Repo

  @type card_queue :: :new | :learn | :review | :day_learn | :suspended | :buried
  @type card_type :: :new | :learn | :review | :relearn

  @type t :: %__MODULE__{
          note_question_index: non_neg_integer(),
          note_answer_index: non_neg_integer(),
          note_id: Ecto.UUID.t(),
          card_type: card_type(),
          card_queue: card_queue(),
          due: DateTime.t(),
          #
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "cards" do
    field :note_question_index, :integer
    field :note_answer_index, :integer
    field :card_type, Ecto.Enum, values: [:new, :learn, :review, :relearn], default: :new
    field :card_queue, Ecto.Enum, values: [:new, :learn, :review, :day_learn, :suspended, :buried], default: :new
    field :due, :utc_datetime

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

defmodule Memorex.Cards.Card do
  @moduledoc false

  use Memorex.Schema

  alias Memorex.Config
  alias Memorex.Cards.{CardLog, Note}
  alias Memorex.{EctoTimexDuration, Repo}
  alias Timex.Duration

  @type card_queue :: :new | :learn | :review | :day_learn | :suspended | :buried
  @type card_type :: :new | :learn | :review | :relearn
  @type answer_choice :: :again | :hard | :ok | :easy

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          #
          card_queue: card_queue(),
          card_type: card_type(),
          due: DateTime.t(),
          ease_factor: float(),
          interval: Duration.t(),
          lapses: non_neg_integer(),
          note_answer_index: non_neg_integer(),
          note_question_index: non_neg_integer(),
          remaining_steps: non_neg_integer(),
          reps: non_neg_integer(),
          #
          note_id: Ecto.UUID.t(),
          #
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "cards" do
    field :card_queue, Ecto.Enum, values: [:new, :learn, :review, :day_learn, :suspended, :buried], default: :new
    field :card_type, Ecto.Enum, values: [:new, :learn, :review, :relearn], default: :new
    field :due, :utc_datetime
    field :ease_factor, :float
    field :interval, EctoTimexDuration
    field :lapses, :integer
    field :note_answer_index, :integer
    field :note_question_index, :integer
    field :remaining_steps, :integer
    field :reps, :integer

    # belongs_to :deck, Deck
    belongs_to :note, Note
    has_many :card_logs, CardLog

    timestamps()
  end

  @spec create_bidirectional_from_note(Note.t()) :: Ecto.Schema.t()
  def(create_bidirectional_from_note(note)) do
    card1 = %__MODULE__{note: note, note_question_index: 0, note_answer_index: 1}
    card2 = %__MODULE__{note: note, note_question_index: 1, note_answer_index: 0}
    Repo.insert!(card1)
    Repo.insert!(card2)
  end

  @spec bracket_time_to_answer(Duration.t(), Config.t()) :: Duration.t()
  def bracket_time_to_answer(time_to_answer, config \\ %Config{}) do
    time_to_answer_in_sec = Duration.to_seconds(time_to_answer)

    if time_to_answer_in_sec > Duration.to_seconds(config.min_time_to_answer) do
      if time_to_answer_in_sec > Duration.to_seconds(config.max_time_to_answer) do
        config.max_time_to_answer
      else
        time_to_answer
      end
    else
      config.min_time_to_answer
    end
  end
end

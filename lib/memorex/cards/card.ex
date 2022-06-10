defmodule Memorex.Cards.Card do
  @moduledoc false

  use Memorex.Schema
  import Ecto.Changeset

  alias Memorex.Cards.{CardLog, Note}
  alias Memorex.{Config, EctoTimexDuration, Repo, Schema}
  alias Timex.Duration

  @type card_queue :: :new | :learn | :review | :day_learn | :suspended | :buried
  @type card_type :: :new | :learn | :review | :relearn

  # Not used yet, but perhaps a replacement for card_queue?
  @type card_status :: :active | :suspended | :buried

  @type answer_choice :: :again | :hard | :good | :easy
  @answer_choices [:again, :hard, :good, :easy]
  @spec answer_choices() :: [answer_choice()]
  def answer_choices(), do: @answer_choices

  @type t :: %__MODULE__{
          id: Schema.id() | nil,
          #
          card_queue: card_queue(),
          card_type: card_type(),
          current_step: non_neg_integer(),
          due: DateTime.t(),
          ease_factor: float(),
          interval: Duration.t(),
          lapses: non_neg_integer(),
          note_answer_index: non_neg_integer(),
          note_question_index: non_neg_integer(),
          reps: non_neg_integer(),
          #
          note_id: Schema.id(),
          #
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "cards" do
    field :card_queue, Ecto.Enum, values: [:new, :learn, :review, :day_learn, :suspended, :buried], default: :new
    field :card_type, Ecto.Enum, values: [:new, :learn, :review, :relearn], default: :new
    field :current_step, :integer
    field :due, :utc_datetime
    field :ease_factor, :float
    field :interval, EctoTimexDuration
    field :lapses, :integer
    field :note_answer_index, :integer
    field :note_question_index, :integer
    field :reps, :integer

    belongs_to :note, Note
    has_one :deck, through: [:note, :deck]
    has_many :card_logs, CardLog, preload_order: [desc: :inserted_at]

    timestamps()
  end

  # Uncomment this typespec once we figure out the defaults for all of the values:
  # @spec new(Config.t()) :: t()
  def new(config) do
    %__MODULE__{ease_factor: config.initial_ease}
  end

  @spec changeset(Ecto.Changeset.t() | t(), map()) :: Ecto.Changeset.t()
  def changeset(card, params \\ %{}) do
    card
    |> cast(params, [
      :card_queue,
      :card_type,
      :current_step,
      :due,
      :ease_factor,
      :interval,
      :lapses,
      :note_answer_index,
      :note_question_index,
      :reps
    ])
  end

  @spec set_due_field_in_changeset(Ecto.Changeset.t() | t(), DateTime.t()) :: Ecto.Changeset.t()
  def set_due_field_in_changeset(changeset, time) do
    interval = Ecto.Changeset.get_field(changeset, :interval)

    changeset
    |> cast(%{due: Timex.add(time, interval)}, [:due])
  end

  @spec create_bidirectional_from_note(Note.t()) :: Schema.id()
  def(create_bidirectional_from_note(note)) do
    card1 = %__MODULE__{note: note, note_question_index: 0, note_answer_index: 1}
    card2 = %__MODULE__{note: note, note_question_index: 1, note_answer_index: 0}
    Repo.insert!(card1)
    Repo.insert!(card2)
  end

  @spec increment_reps(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def increment_reps(changeset) do
    reps = Ecto.Changeset.get_field(changeset, :reps)

    changeset
    |> cast(%{reps: reps + 1}, [:reps])
  end

  @spec new_card_to_learn_card_changeset(Ecto.Changeset.t() | t(), Config.t(), DateTime.t()) :: Ecto.Changeset.t()
  def new_card_to_learn_card_changeset(card, config, time_now) do
    updates = %{
      card_queue: :learn,
      card_type: :learn,
      current_step: 0,
      due: time_now,
      interval: config.learn_steps |> List.first(),
      lapses: 0,
      reps: 0
    }

    changeset(card, updates)
  end

  @spec question(t()) :: String.t()
  def question(card) do
    card.note.content |> List.pop_at(card.note_question_index) |> elem(0)
  end

  @spec answer(t()) :: String.t()
  def answer(card) do
    card.note.content |> List.pop_at(card.note_answer_index) |> elem(0)
  end
end

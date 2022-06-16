defmodule Memorex.Domain.Card do
  @moduledoc false

  use Memorex.Ecto.Schema
  import Ecto.Changeset

  alias Memorex.Domain.{CardLog, Note}
  alias Memorex.Ecto.{TimexDuration, Schema}
  alias Timex.Duration

  @type card_queue :: :new | :learn | :review | :day_learn | :suspended | :buried

  @type card_type :: :new | :learn | :review | :relearn
  @card_types [:new, :learn, :review, :relearn]
  @spec card_types() :: [card_type()]
  def card_types(), do: @card_types

  @type card_status :: :active | :suspended | :buried
  @card_statuses [:active, :suspended, :buried]
  @spec card_statuses() :: [card_status()]
  def card_statuses(), do: @card_statuses

  @type answer_choice :: :again | :hard | :good | :easy
  @answer_choices [:again, :hard, :good, :easy]
  @spec answer_choices() :: [answer_choice()]
  def answer_choices(), do: @answer_choices

  @type t :: %__MODULE__{
          id: Schema.id() | nil,
          #
          card_queue: card_queue(),
          card_status: card_status(),
          card_type: card_type(),
          current_step: non_neg_integer(),
          due: DateTime.t(),
          ease_factor: float(),
          interval: Duration.t(),
          interval_prior_to_lapse: Duration.t(),
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
    field :card_status, Ecto.Enum, values: [:active, :suspended, :buried], default: :active
    field :card_type, Ecto.Enum, values: [:new, :learn, :review, :relearn], default: :new
    field :current_step, :integer
    field :due, :utc_datetime
    field :ease_factor, :float
    field :interval, TimexDuration
    field :interval_prior_to_lapse, TimexDuration
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
    |> cast(convert_duration_strings(params), [
      :card_queue,
      :card_status,
      :card_type,
      :current_step,
      :due,
      :ease_factor,
      :interval,
      :interval_prior_to_lapse,
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

  @spec increment_reps(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def increment_reps(changeset) do
    reps = Ecto.Changeset.get_field(changeset, :reps)

    changeset
    |> cast(%{reps: reps + 1}, [:reps])
  end

  @spec question(t()) :: String.t()
  def question(card) do
    card.note.content |> List.pop_at(card.note_question_index) |> elem(0)
  end

  @spec answer(t()) :: String.t()
  def answer(card) do
    card.note.content |> List.pop_at(card.note_answer_index) |> elem(0)
  end

  @spec convert_duration_strings(map()) :: map()
  defp convert_duration_strings(params) do
    duration_fields = ["interval", "interval_prior_to_lapse"]

    duration_fields
    |> Enum.reduce(params, fn duration_field, acc ->
      if Map.has_key?(acc, duration_field) do
        Map.update!(acc, duration_field, fn value ->
          if is_binary(value), do: Duration.parse!(value), else: value
        end)
      else
        acc
      end
    end)
  end
end

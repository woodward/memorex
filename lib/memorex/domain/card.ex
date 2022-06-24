defmodule Memorex.Domain.Card do
  @moduledoc """
  A `Memorex.Domain.Card` is the entity in Memorex which is reviewed/drilled by `MemorexWeb.ReviewLive`.
  """

  use Memorex.Ecto.Schema
  import Ecto.Changeset

  alias Memorex.Domain.{CardLog, Note}
  alias Memorex.Ecto.{TimexDuration, Schema}
  alias Timex.Duration

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

  @spec changeset(Ecto.Changeset.t() | t(), map()) :: Ecto.Changeset.t()
  def changeset(card, params \\ %{}) do
    card
    |> cast(params, [
      :card_status,
      :card_type,
      :current_step,
      :due,
      :ease_factor,
      :lapses,
      :note_answer_index,
      :note_question_index,
      :reps
    ])
    |> cast_duration_field(:interval, params)
    |> cast_duration_field(:interval_prior_to_lapse, params)
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

  @spec is_image_card?(t()) :: boolean()
  def is_image_card?(card) do
    card.note.image_file_path != nil
  end

  @spec question(t()) :: String.t()
  def question(card) do
    card.note.content |> List.pop_at(card.note_question_index) |> elem(0)
  end

  @spec answer(t()) :: String.t()
  def answer(card) do
    card.note.content |> List.pop_at(card.note_answer_index) |> elem(0)
  end

  # Casts a duration field (i.e., `:interval` or `:interval_prior_to_lapse`.  If the field comes in as a string param
  # (such as "PT30M") then it is converted to a `Time x.Duration`.
  @spec cast_duration_field(Ecto.Changeset.t(), atom(), map()) :: Ecto.Changeset.t()
  defp cast_duration_field(changeset, field_name, params) do
    string_field_name = field_name |> Atom.to_string()

    if Map.has_key?(params, string_field_name) || Map.has_key?(params, field_name) do
      value = Map.get(params, string_field_name)
      value = value || Map.get(params, field_name)
      add_to_changeset = &cast(changeset, %{string_field_name => &1}, [field_name])

      if is_binary(value) do
        case Duration.parse(value) do
          {:ok, duration} -> add_to_changeset.(duration)
          {:error, _reason} -> changeset |> add_error(field_name, "invalid duration")
        end
      else
        add_to_changeset.(value)
      end
    else
      changeset
    end
  end
end

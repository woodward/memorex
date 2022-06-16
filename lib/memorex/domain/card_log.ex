defmodule Memorex.Domain.CardLog do
  @moduledoc false

  use Memorex.Ecto.Schema

  alias Memorex.Ecto.{Schema, TimexDuration}
  alias Memorex.Domain.Card
  alias Timex.Duration

  @type t :: %__MODULE__{
          id: Schema.id() | nil,
          #
          answer_choice: Card.answer_choice(),
          card_status: Card.card_status(),
          card_type: Card.card_type(),
          current_step: non_neg_integer(),
          due: DateTime.t(),
          ease_factor: float(),
          interval: Duration.t(),
          last_card_status: Card.card_status(),
          last_card_type: Card.card_type(),
          last_due: DateTime.t(),
          last_ease_factor: float(),
          last_interval: Duration.t(),
          last_step: non_neg_integer(),
          reps: non_neg_integer(),
          time_to_answer: Duration.t(),
          #
          card_id: Schema.id(),
          #
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "card_logs" do
    field :answer_choice, Ecto.Enum, values: [:again, :hard, :good, :easy]
    field :card_status, Ecto.Enum, values: [:active, :suspended, :buried]
    field :card_type, Ecto.Enum, values: [:new, :learn, :review, :relearn]
    field :current_step, :integer
    field :due, :utc_datetime
    field :ease_factor, :float
    field :interval, TimexDuration
    field :last_card_status, Ecto.Enum, values: [:active, :suspended, :buried]
    field :last_card_type, Ecto.Enum, values: [:new, :learn, :review, :relearn]
    field :last_due, :utc_datetime
    field :last_ease_factor, :float
    field :last_interval, TimexDuration
    field :last_step, :integer
    field :reps, :integer
    field :time_to_answer, TimexDuration

    belongs_to :card, Card
    has_one :note, through: [:card, :note]

    timestamps()
  end

  @spec new(Card.answer_choice() | nil, card_before :: Card.t(), card_after :: Card.t(), time_to_answer :: Duration.t() | nil) :: t()
  def new(answer_choice, card_before, card_after, time_to_answer) do
    %__MODULE__{
      answer_choice: answer_choice,
      card_id: card_before.id,
      card_status: card_after.card_status,
      card_type: card_after.card_type,
      current_step: card_after.current_step,
      due: card_after.due,
      ease_factor: card_after.ease_factor,
      interval: card_after.interval,
      last_card_status: card_before.card_status,
      last_card_type: card_before.card_type,
      last_due: card_before.due,
      last_ease_factor: card_before.ease_factor,
      last_interval: card_before.interval,
      last_step: card_before.current_step,
      reps: card_after.reps,
      time_to_answer: time_to_answer
    }
  end
end

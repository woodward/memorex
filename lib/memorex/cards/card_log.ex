defmodule Memorex.Cards.CardLog do
  @moduledoc false

  use Memorex.Schema

  alias Memorex.{EctoTimexDuration, Schema}
  alias Memorex.Cards.Card
  alias Timex.Duration

  @type t :: %__MODULE__{
          id: Schema.id() | nil,
          #
          answer_choice: Card.answer_choice(),
          card_id: Schema.id(),
          card_type: Card.card_type(),
          due: DateTime.t(),
          ease_factor: float(),
          interval: Duration.t(),
          last_card_type: Card.card_type(),
          last_due: DateTime.t(),
          last_ease_factor: float(),
          last_interval: Duration.t(),
          last_remaining_steps: non_neg_integer(),
          remaining_steps: non_neg_integer(),
          time_to_answer: Duration.t(),
          #
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "card_logs" do
    field :answer_choice, Ecto.Enum, values: [:again, :hard, :good, :easy]
    field :card_type, Ecto.Enum, values: [:new, :learn, :review, :relearn]
    field :due, :utc_datetime
    field :ease_factor, :float
    field :interval, EctoTimexDuration
    field :last_card_type, Ecto.Enum, values: [:new, :learn, :review, :relearn]
    field :last_due, :utc_datetime
    field :last_ease_factor, :float
    field :last_interval, EctoTimexDuration
    field :last_remaining_steps, :integer
    field :remaining_steps, :integer
    field :time_to_answer, EctoTimexDuration

    belongs_to :card, Card
    has_one :note, through: [:card, :note]

    timestamps()
  end

  @spec new(Card.answer_choice(), card_before :: Card.t(), card_after :: Card.t(), time_to_answer :: Duration.t()) :: t()
  def new(answer_choice, card_before, card_after, time_to_answer) do
    %__MODULE__{
      answer_choice: answer_choice,
      card_id: card_before.id,
      card_type: card_after.card_type,
      due: card_after.due,
      ease_factor: card_after.ease_factor,
      interval: card_after.interval,
      last_card_type: card_before.card_type,
      last_due: card_before.due,
      last_ease_factor: card_before.ease_factor,
      last_interval: card_before.interval,
      last_remaining_steps: card_before.remaining_steps,
      remaining_steps: card_after.remaining_steps,
      time_to_answer: time_to_answer
    }
  end
end

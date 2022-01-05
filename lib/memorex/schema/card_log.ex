defmodule Memorex.Schema.CardLog do
  @moduledoc false

  use Memorex.Schema
  alias Memorex.Schema.Card
  alias Timex.Duration

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          card_id: Ecto.UUID.t(),
          card_type: Card.card_type(),
          answer_choice: Card.answer_choice(),
          interval: non_neg_integer(),
          last_interval: non_neg_integer(),
          ease_factor: non_neg_integer(),
          time_to_answer: Duration.t(),
          #
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "card_logs" do
    field :card_type, Ecto.Enum, values: [:new, :learn, :review, :relearn]
    field :answer_choice, Ecto.Enum, values: [:again, :hard, :ok, :easy]
    field(:interval, :integer, null: false)
    field(:last_interval, :integer, null: false)
    field(:ease_factor, :integer, null: false)
    field(:time_to_answer, :integer, null: false)

    belongs_to :card, Card

    timestamps()
  end

  @spec new(Card.answer_choice(), Card.t(), Card.t(), Duration.t()) :: t()
  def new(answer_choice, card_before, card_after, time_to_answer) do
    %__MODULE__{
      answer_choice: answer_choice,
      card_id: card_before.id,
      card_type: card_after.card_type,
      interval: 3,
      last_interval: 3,
      ease_factor: 3,
      time_to_answer: Card.bracket_time_to_answer(time_to_answer)
    }
  end
end

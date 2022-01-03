defmodule Memorex.Schema.CardLog do
  @moduledoc false

  use Memorex.Schema
  alias Memorex.Schema.Card

  @type t :: %__MODULE__{
          card_id: Ecto.UUID.t(),
          card_type: Card.card_type(),
          answer_choice: Card.answer_choice(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "card_logs" do
    field :card_type, Ecto.Enum, values: [:new, :learn, :review, :relearn]
    field :answer_choice, Ecto.Enum, values: [:again, :hard, :ok, :easy]

    belongs_to :card, Card

    timestamps()
  end

  @spec new(Card.answer_choice(), Card.t(), Card.t(), Timex.Duration.t()) :: __MODULE__.t()
  def new(answer_choice, card_before, _card_after, _time_to_answer) do
    %__MODULE__{answer_choice: answer_choice, card_id: card_before.id, card_type: card_before.card_type}
  end
end

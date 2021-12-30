defmodule Memorex.CardLog do
  @moduledoc false

  use Memorex.Schema
  alias Memorex.Card

  @type answer_choice :: :again | :hard | :ok | :easy

  @type t :: %__MODULE__{
          card_id: Ecto.UUID.t(),
          card_type: Card.card_type(),
          answer_choice: answer_choice(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "card_logs" do
    field :card_type, Ecto.Enum, values: [:new, :learn, :review, :relearn]
    field :answer_choice, Ecto.Enum, values: [:again, :hard, :ok, :easy]

    belongs_to :card, Card

    timestamps()
  end
end

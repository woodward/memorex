defmodule Memorex.DeckStats do
  @moduledoc false

  alias Memorex.Cards
  alias Memorex.Ecto.Schema

  @type t :: %__MODULE__{
          total: non_neg_integer(),
          new: non_neg_integer(),
          learn: non_neg_integer(),
          review: non_neg_integer(),
          due: non_neg_integer()
        }

  defstruct [:total, :new, :learn, :review, :due]

  @spec new(Schema.id(), DateTime.t()) :: t()
  def new(deck_id, time_now) do
    %__MODULE__{
      total: Cards.count(deck_id),
      new: Cards.count(deck_id, :new),
      learn: Cards.count(deck_id, :learn),
      review: Cards.count(deck_id, :review),
      due: Cards.due_count(deck_id, time_now)
    }
  end
end

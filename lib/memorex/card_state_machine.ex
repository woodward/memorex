defmodule Memorex.CardStateMachine do
  @moduledoc false

  alias Memorex.Cards.Card
  alias Memorex.Config

  @spec answer_card(Card.t(), Card.answer_choice(), Config.t()) :: map()
  def answer_card(%Card{card_type: :learn} = _card, :easy, _config) do
    %{card_type: :review}
  end

  def answer_card(%Card{card_type: :learn} = card, :good, config) do
    if card.remaining_steps == 0 do
      %{card_type: :review}
    else
      %{remaining_steps: card.remaining_steps - 1}
    end
  end
end

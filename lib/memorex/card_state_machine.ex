defmodule Memorex.CardStateMachine do
  @moduledoc false

  alias Memorex.Cards.Card
  alias Memorex.Config
  alias Timex.Duration

  @spec answer_card(Card.t(), Card.answer_choice(), Config.t()) :: Ecto.Changeset.t()
  def answer_card(%Card{card_type: :learn} = _card, :easy, _config) do
    %{card_type: :review}
  end

  def answer_card(%Card{card_type: :learn} = _card, :good, _config) do
    %{card_type: :review}
  end

  @spec bracket_time_to_answer(Duration.t(), Config.t()) :: Duration.t()
  def bracket_time_to_answer(time_to_answer, config \\ %Config{}) do
    time_to_answer_in_sec = Duration.to_seconds(time_to_answer)

    if time_to_answer_in_sec > Duration.to_seconds(config.min_time_to_answer) do
      if time_to_answer_in_sec > Duration.to_seconds(config.max_time_to_answer) do
        config.max_time_to_answer
      else
        time_to_answer
      end
    else
      config.min_time_to_answer
    end
  end
end

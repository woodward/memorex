defmodule Memorex.Scheduler do
  @moduledoc false

  alias Memorex.Schema.Card
  alias Timex.Duration

  defmodule Config do
    @moduledoc false
    @type t() :: %__MODULE__{learn_ahead_time_interval: Duration.t()}

    defstruct learn_ahead_time_interval: Timex.Duration.parse!("PT20M")
  end

  @spec answer_card(Card.t(), Card.answer_choice(), __MODULE__.Config.t()) :: Card.t()
  def answer_card(card, _answer_choice, _scheduler_config) do
    %{card | card_queue: :learn, card_type: :learn, due: Timex.now()}
  end

  @spec is_card_due?(Card.t(), DateTime.t() | nil) :: boolean()
  def is_card_due?(%Card{card_queue: :new} = _card, _now), do: true

  def is_card_due?(card, now) do
    case DateTime.compare(card.due, now) do
      :lt -> true
      _ -> false
    end
  end

  @spec learn_ahead_time(DateTime.t() | nil) :: DateTime.t()
  def learn_ahead_time(now \\ Timex.now()) do
    config = %Config{}
    Timex.add(now, config.learn_ahead_time_interval)
  end
end

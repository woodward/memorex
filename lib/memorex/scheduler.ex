defmodule Memorex.Scheduler do
  @moduledoc false

  alias Memorex.Schema.Card

  defmodule Config do
    @moduledoc false
    @type t() :: %__MODULE__{foobar: :atom}

    defstruct [:foobar]
  end

  @spec answer_card(Card.t(), Card.answer_choice(), __MODULE__.Config.t()) :: Card.t()
  def answer_card(card, _answer_choice, _scheduler_config) do
    %{card | card_queue: :learn, card_type: :learn, due: Timex.now()}
  end
end

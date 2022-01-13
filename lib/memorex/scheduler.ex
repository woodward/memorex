defmodule Memorex.Scheduler do
  @moduledoc false

  alias Memorex.Schema.Card
  alias Timex.Duration

  defmodule Config do
    @moduledoc false

    @type t() :: %__MODULE__{
            learn_ahead_time_interval: Duration.t(),
            #
            learn_steps: [float()],
            relearn_steps: [float()],
            #
            initial_ease: non_neg_integer(),
            #
            easy_multiplier: float(),
            hard_multiplier: float(),
            lapse_multiplier: float(),
            interval_multiplier: float(),
            #
            max_review_interval: Duration.t(),
            min_review_interval: Duration.t(),
            #
            graduating_interval_good: non_neg_integer(),
            graduating_interval_easy: non_neg_integer(),
            #
            timezone: String.t()
          }

    defstruct learn_ahead_time_interval: Duration.parse!("PT20M"),
              #
              learn_steps: [1.0, 10.0],
              relearn_steps: [1.0, 10.0],
              #
              initial_ease: 2_500,
              #
              easy_multiplier: 1.3,
              hard_multiplier: 1.2,
              lapse_multiplier: 0.0,
              interval_multiplier: 0.0,
              #
              max_review_interval: Duration.parse!("PT10H"),
              min_review_interval: Duration.parse!("PT1S"),
              #
              graduating_interval_good: 1,
              graduating_interval_easy: 4,
              #
              timezone: Timex.Timezone.Local.lookup()

    # leech_threshold: 7,
  end

  @spec answer_card(Card.t(), Card.answer_choice(), __MODULE__.Config.t()) :: Card.t()
  def answer_card(card, _answer_choice, _scheduler_config) do
    %{card | card_queue: :learn, card_type: :learn, due: Timex.now()}
  end

  @spec is_card_due?(Card.t(), DateTime.t() | nil) :: boolean()
  def is_card_due?(%Card{card_queue: :new} = _card, _now), do: true
  def is_card_due?(%Card{card_queue: :buried}, _now), do: false
  def is_card_due?(%Card{card_queue: :suspended}, _now), do: false

  def is_card_due?(%Card{card_queue: :learn} = card, now) do
    case DateTime.compare(card.due, learn_ahead_time(now)) do
      :gt -> false
      _ -> true
    end
  end

  def is_card_due?(%Card{card_queue: :day_learn} = card, now) do
    case DateTime.compare(card.due, Timex.end_of_day(now)) do
      :gt -> false
      _ -> true
    end
  end

  def is_card_due?(%Card{card_queue: :review} = card, now) do
    case DateTime.compare(card.due, Timex.end_of_day(now)) do
      :gt -> false
      _ -> true
    end
  end

  @spec learn_ahead_time(DateTime.t() | nil) :: DateTime.t()
  def learn_ahead_time(now \\ Timex.now()) do
    config = %Config{}
    Timex.add(now, config.learn_ahead_time_interval)
  end
end

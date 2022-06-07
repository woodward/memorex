defmodule Memorex.Config do
  @moduledoc false

  alias Timex.Duration

  @type t() :: %__MODULE__{
          new_cards_per_day: nil | non_neg_integer(),
          max_reviews_per_day: nil | non_neg_integer(),
          #
          learn_ahead_time_interval: Duration.t(),
          #
          learn_steps: [Duration.t()],
          graduating_interval_good: Duration.t(),
          graduating_interval_easy: Duration.t(),
          #
          relearn_steps: [Duration.t()],
          #
          initial_ease: float(),
          #
          easy_multiplier: float(),
          hard_multiplier: float(),
          lapse_multiplier: float(),
          interval_multiplier: float(),
          #
          ease_again: float(),
          ease_hard: float(),
          ease_good: float(),
          ease_easy: float(),
          #
          max_review_interval: Duration.t(),
          min_review_interval: Duration.t(),
          #
          #
          leech_threshold: non_neg_integer(),
          #
          min_time_to_answer: Duration.t(),
          max_time_to_answer: Duration.t(),
          #
          relearn_easy_adj: Duration.t(),
          #
          timezone: String.t()
        }

  defstruct [
    :new_cards_per_day,
    :max_reviews_per_day,
    #
    learn_ahead_time_interval: Duration.parse!("PT20M"),
    #
    learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")],
    graduating_interval_good: Duration.parse!("P1D"),
    graduating_interval_easy: Duration.parse!("P4D"),
    #
    relearn_steps: [Duration.parse!("PT10M")],
    #
    initial_ease: 2.5,
    #
    easy_multiplier: 1.3,
    hard_multiplier: 1.2,
    lapse_multiplier: 0.0,
    interval_multiplier: 1.0,
    #
    ease_again: -0.2,
    ease_hard: -0.15,
    ease_good: 0.0,
    ease_easy: 0.15,
    #
    max_review_interval: Duration.parse!("P100Y"),
    min_review_interval: Duration.parse!("P1D"),
    #
    leech_threshold: 8,
    #
    min_time_to_answer: Duration.parse!("PT1S"),
    max_time_to_answer: Duration.parse!("PT1M"),
    #
    relearn_easy_adj: Duration.parse!("P1D"),
    #
    timezone: Timex.Timezone.Local.lookup()
  ]

  def default() do
    config = Application.get_env(:memorex, __MODULE__)

    %__MODULE__{
      new_cards_per_day: config[:new_cards_per_day],
      max_reviews_per_day: config[:max_reviews_per_day]
    }
  end
end

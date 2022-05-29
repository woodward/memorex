defmodule Memorex.Config do
  @moduledoc false

  alias Timex.Duration

  @type t() :: %__MODULE__{
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
          max_reviews_per_day: non_neg_integer(),
          easy_multiplier: float(),
          hard_multiplier: float(),
          lapse_multiplier: float(),
          interval_multiplier: float(),
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
          timezone: String.t()
        }

  defstruct learn_ahead_time_interval: Duration.parse!("PT20M"),
            #
            learn_steps: [Duration.parse!("PT1M"), Duration.parse!("PT10M")],
            graduating_interval_good: Duration.parse!("P1D"),
            graduating_interval_easy: Duration.parse!("P4D"),
            #
            relearn_steps: [Duration.parse!("PT10M")],
            #
            initial_ease: 2.5,
            #
            max_reviews_per_day: 9999,
            easy_multiplier: 1.3,
            hard_multiplier: 1.2,
            lapse_multiplier: 0.0,
            interval_multiplier: 0.0,
            #
            max_review_interval: Duration.parse!("P100Y"),
            min_review_interval: Duration.parse!("P1D"),
            #
            leech_threshold: 8,
            #
            min_time_to_answer: Duration.parse!("PT1S"),
            max_time_to_answer: Duration.parse!("PT1M"),
            #
            timezone: Timex.Timezone.Local.lookup()
end

defmodule Memorex.Config do
  @moduledoc false

  alias Timex.Duration

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

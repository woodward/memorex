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
    :learn_ahead_time_interval,
    #
    :learn_steps,
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

  @duration_fields [
    :learn_ahead_time_interval,
    #
    :graduating_interval_good,
    :graduating_interval_easy,
    #
    :max_review_interval,
    :min_review_interval,
    #
    :min_time_to_answer,
    :max_time_to_answer,
    #
    :relearn_easy_adj
  ]

  @duration_array_fields [:learn_steps, :relearn_steps]

  def default() do
    config = Application.get_env(:memorex, __MODULE__)

    %__MODULE__{
      new_cards_per_day: config[:new_cards_per_day],
      max_reviews_per_day: config[:max_reviews_per_day],
      #
      learn_ahead_time_interval: config[:learn_ahead_time_interval],
      #
      learn_steps: config[:learn_steps]
    }
  end

  @spec merge(map(), t()) :: t()
  def merge(default_config, deck_config) do
    config = Map.merge(default_config, atomize_keys(deck_config))

    config =
      @duration_fields
      |> Enum.reduce(config, fn field_name, config ->
        Map.put(config, field_name, convert_string_to_duration(Map.get(config, field_name)))
      end)

    @duration_array_fields
    |> Enum.reduce(config, fn field_name, config ->
      converted_array_values = Map.get(config, field_name) |> Enum.map(&convert_string_to_duration(&1))
      Map.put(config, field_name, converted_array_values)
    end)
  end

  @spec atomize_keys(map()) :: map()
  def atomize_keys(map), do: map |> Enum.into(%{}, fn {key, value} -> {String.to_atom(key), value} end)

  @spec convert_string_to_duration(String.t() | Duration.t()) :: Duration.t()
  defp convert_string_to_duration(duration) when is_binary(duration), do: Duration.parse!(duration)
  defp convert_string_to_duration(duration), do: duration
end

defmodule Memorex.Config do
  @moduledoc false

  alias Timex.Duration

  @type t() :: %__MODULE__{
          new_cards_per_day: nil | non_neg_integer(),
          max_reviews_per_day: nil | non_neg_integer(),
          #
          learn_ahead_time_interval: nil | Duration.t(),
          #
          learn_steps: nil | [Duration.t()],
          graduating_interval_good: nil | Duration.t(),
          graduating_interval_easy: nil | Duration.t(),
          #
          relearn_steps: nil | [Duration.t()],
          #
          initial_ease: nil | float(),
          #
          easy_multiplier: nil | float(),
          hard_multiplier: nil | float(),
          lapse_multiplier: nil | float(),
          interval_multiplier: nil | float(),
          #
          ease_again: nil | float(),
          ease_hard: nil | float(),
          ease_good: nil | float(),
          ease_easy: nil | float(),
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
    :graduating_interval_good,
    :graduating_interval_easy,
    #
    :relearn_steps,
    #
    :initial_ease,
    #
    :easy_multiplier,
    :hard_multiplier,
    :lapse_multiplier,
    :interval_multiplier,
    #
    :ease_again,
    :ease_hard,
    :ease_good,
    :ease_easy,
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
      learn_steps: config[:learn_steps],
      graduating_interval_good: config[:graduating_interval_good],
      graduating_interval_easy: config[:graduating_interval_easy],
      #
      relearn_steps: config[:relearn_steps],
      #
      initial_ease: config[:initial_ease],
      #
      easy_multiplier: config[:easy_multiplier],
      hard_multiplier: config[:hard_multiplier],
      lapse_multiplier: config[:lapse_multiplier],
      interval_multiplier: config[:interval_multiplier],
      #
      ease_again: config[:ease_again],
      ease_hard: config[:ease_hard],
      ease_good: config[:ease_good],
      ease_easy: config[:ease_easy]
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

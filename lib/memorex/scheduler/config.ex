defmodule Memorex.Scheduler.Config do
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
          max_review_interval: nil | Duration.t(),
          min_review_interval: nil | Duration.t(),
          #
          #
          leech_threshold: nil | non_neg_integer(),
          #
          min_time_to_answer: nil | Duration.t(),
          max_time_to_answer: nil | Duration.t(),
          #
          relearn_easy_adj: nil | Duration.t(),
          #
          timezone: nil | String.t()
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
    :max_review_interval,
    :min_review_interval,
    #
    :leech_threshold,
    #
    :min_time_to_answer,
    :max_time_to_answer,
    #
    :relearn_easy_adj,
    #
    :timezone
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
    Application.get_env(:memorex, __MODULE__)
    |> Enum.reduce(%__MODULE__{}, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
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

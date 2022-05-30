defmodule Memorex.Cards do
  @moduledoc false

  alias Memorex.Cards.Card
  alias Memorex.{Config, Repo}

  @spec update_card!(Card.t(), map(), DateTime.t()) :: Card.t()
  def update_card!(card, changes, time) do
    card
    |> Card.changeset(changes)
    |> Card.set_due_field_in_changeset(time)
    |> Repo.update!()
  end

  @spec update_new_cards_to_learn_cards(Ecto.Queryable.t(), Config.t(), DateTime.t(), Keyword.t()) :: :ok
  def update_new_cards_to_learn_cards(queryable, config, time_now, opts \\ []) do
    first_learn_step = config.learn_steps |> List.first()

    updates = [
      interval: first_learn_step,
      remaining_steps: length(config.learn_steps),
      card_type: :learn,
      ease_factor: config.initial_ease,
      lapses: 0,
      reps: 0,
      card_queue: :learn,
      due: Timex.shift(time_now, duration: first_learn_step)
    ]

    Repo.update_all(queryable, [set: updates], opts)
  end
end

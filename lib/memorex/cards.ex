defmodule Memorex.Cards do
  @moduledoc false

  alias Memorex.Cards.Card
  alias Memorex.Repo

  @spec update_card!(Card.t(), map(), DateTime.t()) :: Card.t()
  def update_card!(card, changes, time) do
    card
    |> Card.changeset(changes)
    |> Card.set_due_field_in_changeset(time)
    |> Repo.update!()
  end
end

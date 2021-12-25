defmodule Memorex.Scheduler do
  @moduledoc false

  alias Memorex.{Deck, Repo}
  import Ecto.Query

  def get_cards_for_drilling(decks) do
    deck_ids = decks |> Enum.map(& &1.id)

    # Currently just returns all of the cards for all of the decks; this will be changed later
    from(d in Deck, where: d.id in ^deck_ids)
    |> Repo.all()
    |> Repo.preload([:notes, :cards])
    |> Enum.reduce([], fn deck, acc ->
      deck.cards ++ acc
    end)
  end
end

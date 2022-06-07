defmodule Memorex.Decks do
  @moduledoc false

  alias Memorex.Repo
  alias Memorex.Cards.Deck

  @spec find_or_create!(String.t()) :: Deck.t()
  def find_or_create!(name) do
    case Repo.get_by(Deck, name: name) do
      nil -> Repo.insert!(%Deck{name: name})
      deck -> deck
    end
  end

  @spec update_config(Deck.t(), map()) :: Deck.t()
  def update_config(deck, config) do
    deck
    |> Deck.changeset(%{config: config})
    |> Repo.update!()
  end
end

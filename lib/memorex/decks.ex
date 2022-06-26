defmodule Memorex.Decks do
  @moduledoc """
  Functions for interacting with `Memorex.Domain.Deck`s.
  """

  alias Memorex.Ecto.Repo
  alias Memorex.Domain.Deck

  @doc """
  Finds an existing deck by name, or else creates it.
  """
  @spec find_or_create!(String.t()) :: Deck.t()
  def find_or_create!(name) do
    case Repo.get_by(Deck, name: name) do
      nil -> Repo.insert!(%Deck{name: name})
      deck -> deck
    end
  end

  @doc """
  Updates the config for a `Memorex.Domain.Deck` from the values contained in a TOML deck config file.  Note that only
  the values from the config file are stored (which might be a subset of the available values contained in
  `Memorex.Scheduler.Config`), and they are stored in the database as a `Map`, NOT as a `Memorex.Scheduler.Config` struct.
  """
  @spec update_config(Deck.t(), map()) :: Deck.t()
  def update_config(deck, config) do
    deck
    |> Deck.changeset(%{config: config})
    |> Repo.update!()
  end
end

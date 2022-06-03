defmodule MemorexWeb.ReviewLive do
  @moduledoc false
  use MemorexWeb, :live_view

  alias Memorex.{Cards, Config, Repo}
  alias Memorex.Cards.Deck

  @impl true
  def render(assigns) do
    ~H"""
    <h1> Deck <%= @deck.name %> </h1>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    deck = Repo.get!(Deck, params["deck"])
    config = %Config{}
    time_now = Timex.now()
    Cards.set_new_cards_in_deck_to_learn_cards(deck.id, config, time_now, limit: config.new_cards_per_day)
    {:noreply, socket |> assign(deck: deck, config: config)}
  end
end

defmodule MemorexWeb.ReviewLive do
  @moduledoc false
  use MemorexWeb, :live_view

  alias Memorex.{Cards, Config, Repo}
  alias Memorex.Cards.{Card, Deck}

  @impl true
  def render(assigns) do
    ~H"""
    <h1> Deck <%= @deck.name %> </h1>

    <h3> <%= Card.question(@card) %> </h3>
    <h3> <%= Card.answer(@card) %> </h3>
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
    card = Cards.get_one_random_due_card(deck.id, time_now)
    {:noreply, socket |> assign(deck: deck, config: config, card: card)}
  end
end

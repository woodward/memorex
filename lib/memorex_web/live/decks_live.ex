defmodule MemorexWeb.DecksLive do
  @moduledoc """
  A Phoenix LiveView which shows a list of all decks.  This is the main UI entry point to the application.
  """
  use MemorexWeb, :live_view

  alias Memorex.{Cards, DeckStats, TimeUtils}
  alias Memorex.Scheduler.Config
  alias Memorex.Domain.Deck
  alias Memorex.Ecto.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="title">Decks</h1>

    <div>
      <table class="table">
        <thead>
          <th>Deck</th>
          <th>Total</th>
          <th>New</th>
          <th>Learn</th>
          <th>Review</th>
          <th>Due</th>
          <th>Suspended</th>
          <th></th>
          <th>Actions</th>
          <th></th>
        </thead>
        <tbody>
          <%= for {deck, deck_stats} <- @decks do %>
            <tr>
              <td class="has-text-weight-bold"><%= deck.name %></td>
              <td><%= deck_stats.total %></td>
              <td><%= deck_stats.new %></td>
              <td><%= deck_stats.learn %></td>
              <td><%= deck_stats.review %></td>
              <td><%= deck_stats.due %></td>
              <td><%= deck_stats.suspended %></td>
              <td>
                <.link href={~p"/review?#{[deck: deck]}"} class="btn">Review/Drill</.link>
              </td>
              <td>
                <a phx-click="add-new-batch-of-learn-cards" phx-value-deck_id={deck.id} class="btn"> Add New Learn Cards </a>
              </td>
              <td>
                <.link href={~p"/cards?#{[deck_id: deck.id]}"} class="btn">All Cards</.link>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    decks = Repo.all(Deck)
    default_config = Config.default()

    decks =
      decks
      |> Enum.reduce(%{}, fn deck, acc ->
        Phoenix.PubSub.subscribe(Memorex.PubSub, "deck:#{deck.id}")
        Map.put(acc, deck, DeckStats.new(deck.id, TimeUtils.now()))
      end)

    {:ok, socket |> assign(decks: decks, default_config: default_config)}
  end

  @impl true
  def handle_event(
        "add-new-batch-of-learn-cards",
        %{"deck_id" => deck_id} = _params,
        %{assigns: %{default_config: default_config, decks: decks}} = socket
      ) do
    time_now = TimeUtils.now()
    deck = Repo.get!(Deck, deck_id)
    config = default_config |> Config.merge(deck.config)
    Cards.set_new_cards_in_deck_to_learn_cards(deck_id, config, time_now, limit: config.new_cards_per_day)
    decks = Map.put(decks, Repo.get(Deck, deck_id), DeckStats.new(deck_id, time_now))
    {:noreply, socket |> assign(decks: decks)}
  end

  @impl true
  def handle_info({:updated_deck, deck_id}, %{assigns: %{decks: decks}} = socket) do
    time_now = TimeUtils.now()
    decks = Map.put(decks, Repo.get(Deck, deck_id), DeckStats.new(deck_id, time_now))
    {:noreply, socket |> assign(decks: decks)}
  end
end

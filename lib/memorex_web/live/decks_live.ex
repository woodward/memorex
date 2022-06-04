defmodule MemorexWeb.DecksLive do
  @moduledoc false
  use MemorexWeb, :live_view
  alias Memorex.{Cards, Config, Repo, TimeUtils}
  alias Memorex.Cards.Deck
  alias MemorexWeb.Router.Helpers, as: Routes

  @impl true
  def render(assigns) do
    ~H"""
    <h1> Decks </h1>

    <ul>
      <%= for {deck, deck_stats} <- @decks do %>
        <li>
          <%=  live_patch deck.name, to: Routes.review_path(@socket, :home, %{deck: deck}) %>
          (Total: <%= deck_stats.total %>,
          New: <%= deck_stats.new %>,
          Learn: <%= deck_stats.learn %>,
          Review: <%= deck_stats.review %> )
          <button phx-click="add-new-batch-of-learn-cards" phx-value-deck_id={ deck.id }> Add New Batch of Cards </button>
        </li>
      <% end %>
    </ul>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    decks = Repo.all(Deck)
    config = %Config{}

    decks =
      decks
      |> Enum.reduce(%{}, fn deck, acc ->
        Map.put(acc, deck, MemorexWeb.ReviewLive.deck_stats(deck.id))
      end)

    {:ok, socket |> assign(decks: decks, config: config)}
  end

  @impl true
  def handle_event("add-new-batch-of-learn-cards", %{"deck_id" => deck_id} = _params, %{assigns: %{config: config, decks: decks}} = socket) do
    IO.puts("======================")

    Cards.set_new_cards_in_deck_to_learn_cards(deck_id, config, TimeUtils.now(), limit: config.new_cards_per_day)
    decks = Map.put(decks, Repo.get(Deck, deck_id), MemorexWeb.ReviewLive.deck_stats(deck_id))
    {:noreply, socket |> assign(decks: decks)}
  end
end

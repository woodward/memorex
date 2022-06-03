defmodule MemorexWeb.DecksLive do
  @moduledoc false
  use MemorexWeb, :live_view
  alias Memorex.{Cards, Config, Repo}
  alias Memorex.Cards.Deck
  alias MemorexWeb.Router.Helpers, as: Routes

  @impl true
  def render(assigns) do
    ~H"""
    <h1> Decks </h1>

    <ul>
      <%= for deck <- @decks do %>
        <li>
          <%=  live_patch deck.name, to: Routes.review_path(@socket, :home, %{deck: deck}) %>
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
    {:ok, socket |> assign(decks: decks, config: config)}
  end

  @impl true
  def handle_event("add-new-batch-of-learn-cards", %{"deck_id" => deck_id} = _params, %{assigns: %{config: config}} = socket) do
    IO.puts("======================")

    Cards.set_new_cards_in_deck_to_learn_cards(deck_id, config, Timex.now(), limit: config.new_cards_per_day)
    {:noreply, socket}
  end
end

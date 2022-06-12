defmodule MemorexWeb.DecksLive do
  @moduledoc false
  use MemorexWeb, :live_view
  alias Memorex.{Cards, DeckStats, TimeUtils}
  alias Memorex.Scheduler.Config
  alias Memorex.Domain.Deck
  alias Memorex.Ecto.Repo
  alias MemorexWeb.Router.Helpers, as: Routes

  @impl true
  def render(assigns) do
    ~H"""
    <h1> Decks </h1>

    <div class="content">
      <ul>
        <%= for {deck, deck_stats} <- @decks do %>
          <li>
            <%=  deck.name %>
            (Total: <%= deck_stats.total %>,
            New: <%= deck_stats.new %>,
            Learn: <%= deck_stats.learn %>,
            Review: <%= deck_stats.review %>,
            Due: <%= deck_stats.due %> )
            <%= live_patch "All Cards", to: Routes.card_index_path(@socket, :index, %{deck_id: deck.id}) %>
            <%= live_patch "Review", to: Routes.review_path(@socket, :home, %{deck: deck}) %>
            <a phx-click="add-new-batch-of-learn-cards" phx-value-deck_id={ deck.id }> Add New Cards </a>
          </li>
        <% end %>
      </ul>
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
end

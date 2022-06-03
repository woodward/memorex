defmodule MemorexWeb.DecksLive do
  @moduledoc false
  use MemorexWeb, :live_view
  alias Memorex.Repo
  alias Memorex.Cards.Deck
  alias MemorexWeb.Router.Helpers, as: Routes

  @impl true
  def render(assigns) do
    ~H"""
    <h1> Decks </h1>

    <ul>
      <%= for deck <- @decks do %>
        <li> <%=  live_patch deck.name, to: Routes.review_path(@socket, :home, %{deck: deck}) %> </li>
      <% end %>
    </ul>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    decks = Repo.all(Deck)
    {:ok, socket |> assign(decks: decks)}
  end
end

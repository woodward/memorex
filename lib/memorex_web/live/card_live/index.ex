defmodule MemorexWeb.CardLive.Index do
  @moduledoc false

  use MemorexWeb, :live_view

  alias Memorex.Cards
  alias Memorex.Ecto.Repo
  alias Memorex.Domain.Card

  require Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"deck_id" => deck_id} = _params, _url, socket) do
    cards = Cards.cards_for_deck(deck_id) |> Ecto.Query.order_by(asc: :due) |> Repo.all() |> Repo.preload([:note])

    {:noreply, socket |> assign(cards: cards)}
  end
end

defmodule MemorexWeb.CardLive.Edit do
  @moduledoc false

  use MemorexWeb, :live_view

  alias Memorex.Cards
  alias Memorex.Domain.Card

  @impl true
  def mount(%{"id" => _card_id} = _params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    card = Cards.get_card!(id)

    {:noreply,
     socket
     |> assign(card: card, changset: Card.changeset(card, %{}))}
  end
end

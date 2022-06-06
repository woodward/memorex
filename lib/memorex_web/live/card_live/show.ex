defmodule MemorexWeb.CardLive.Show do
  @moduledoc false

  use MemorexWeb, :live_view

  alias Memorex.Cards

  @impl true
  def mount(%{"id" => card_id} = _params, _session, socket) do
    Phoenix.PubSub.subscribe(Memorex.PubSub, "card:#{card_id}")

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    card = Cards.get_card!(id)

    {:noreply,
     socket
     |> assign(
       card: card,
       card_log: card.card_logs |> List.first()
     )}
  end

  @impl true
  def handle_info(:updated_card, %{assigns: %{card: card}} = socket) do
    card = Cards.get_card!(card.id)

    {:noreply,
     socket
     |> assign(
       card: card,
       card_log: card.card_logs |> List.first()
     )}
  end
end

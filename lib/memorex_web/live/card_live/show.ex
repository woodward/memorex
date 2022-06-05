defmodule MemorexWeb.CardLive.Show do
  @moduledoc false

  use MemorexWeb, :live_view

  alias Memorex.Cards

  @impl true
  def mount(_params, _session, socket) do
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
end

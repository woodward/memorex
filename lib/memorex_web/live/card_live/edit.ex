defmodule MemorexWeb.CardLive.Edit do
  @moduledoc false

  use MemorexWeb, :live_view

  alias Memorex.Cards
  alias Memorex.Domain.Card
  alias Timex.Duration

  @impl true
  def mount(%{"id" => _card_id} = _params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    card = Cards.get_card!(id)

    {:noreply,
     socket
     |> assign(card: card, changeset: Card.changeset(card, %{}))}
  end

  @impl true
  def handle_event("validate", %{"card" => card_params}, socket) do
    changeset =
      socket.assigns.card
      |> Card.changeset(card_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"card" => card_params}, %{assigns: %{card: card}} = socket) do
    case Cards.update(card, card_params) do
      {:ok, _card} ->
        {:noreply,
         socket
         |> put_flash(:info, "Card updated successfully")
         |> push_redirect(to: Routes.card_show_path(socket, :show, card.id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @spec duration_string(nil | String.t() | Duration.t()) :: nil | String.t()
  def duration_string(nil), do: nil
  def duration_string(duration) when is_binary(duration), do: duration
  def duration_string(%Duration{} = duration), do: Duration.to_string(duration)
end

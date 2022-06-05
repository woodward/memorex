defmodule MemorexWeb.CardLive.Show do
  @moduledoc false

  use MemorexWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  # @impl true
  # def handle_params(%{"id" => id}, _, socket) do
  #   {:noreply,
  #    socket
  #    |> assign(:user, Accounts.get_user!(id))}
  # end
end

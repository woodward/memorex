defmodule MemorexWeb.DecksLive do
  @moduledoc false
  use MemorexWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <h1> Hello! </h1>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

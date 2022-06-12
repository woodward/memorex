defmodule MemorexWeb.CardLive.CardComponent do
  @moduledoc false

  use MemorexWeb, :live_component

  alias Memorex.Domain.Card
  alias Phoenix.LiveView.Socket

  @spec step(nil | non_neg_integer()) :: String.t() | non_neg_integer()
  def step(nil), do: "-"
  def step(step_number), do: step_number

  @spec show_card_history_link?(Socket.t()) :: boolean()
  def show_card_history_link?(%Socket{view: MemorexWeb.CardLive.Show} = _socket), do: false
  def show_card_history_link?(_socket), do: true
end

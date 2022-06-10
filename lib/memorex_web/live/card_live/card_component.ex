defmodule MemorexWeb.CardLive.CardComponent do
  @moduledoc false

  use MemorexWeb, :live_component

  alias Memorex.Cards.Card

  @spec step(nil | non_neg_integer()) :: String.t() | non_neg_integer()
  def step(nil), do: "-"
  def step(step_number), do: step_number
end

defmodule MemorexWeb.CardLive.CardComponent do
  @moduledoc false

  use MemorexWeb, :live_component

  alias Memorex.TimeUtils
  alias Memorex.Cards.Card

  def format_datetime(%DateTime{} = datetime) do
    # See: https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Strftime.html
    datetime |> TimeUtils.to_timezone() |> Timex.format!("%a, %b %e, %Y, %l:%M %P", :strftime)
  end

  @spec ease_factor(float() | nil) :: String.t()
  def ease_factor(nil), do: "-"
  def ease_factor(ease_factor), do: ease_factor
end

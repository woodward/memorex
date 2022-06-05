defmodule MemorexWeb.CardLive.CardComponent do
  @moduledoc false

  use MemorexWeb, :live_component

  alias Memorex.TimeUtils
  alias Memorex.Cards.Card
  alias Timex.Duration

  # This function is shared with ReviewLive - factor it out into some place that's shared
  @spec format(Duration.t() | DateTime.t()) :: String.t()
  def format(%Duration{} = duration), do: Timex.Format.Duration.Formatters.Humanized.format(duration)

  # See: https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Strftime.html
  def format(%DateTime{} = datetime), do: datetime |> TimeUtils.to_timezone() |> Timex.format!("%a, %b %e, %Y, %l:%M %P", :strftime)

  @spec ease_factor(float() | nil) :: String.t()
  def ease_factor(nil), do: "-"
  def ease_factor(ease_factor), do: ease_factor
end

defmodule MemorexWeb.SharedViewHelpers do
  @moduledoc false

  use Phoenix.HTML

  alias Memorex.TimeUtils
  alias Timex.Duration

  @spec format(Duration.t() | DateTime.t() | nil) :: String.t()
  def format(nil), do: "-"

  def format(%Duration{} = duration) do
    Timex.Format.Duration.Formatters.Humanized.format(duration)
    |> strip_off_seconds()
    |> strip_off_milliseconds()
    |> zero_microseconds_to_now()
  end

  @spec truncate(String.t(), Keyword.t()) :: String.t()
  def truncate(text, options \\ [])

  def truncate(text, options) when is_binary(text) do
    desired_text_length = options[:length] || 30
    omission_chars = options[:omission] || "..."

    if String.length(text) < desired_text_length do
      text
    else
      length_with_omission = desired_text_length - String.length(omission_chars)
      "#{String.slice(text, 0, length_with_omission)}#{omission_chars}"
    end
  end

  def truncate(text, _options), do: text

  @spec page_id(atom()) :: String.t()
  def page_id(socket_view) do
    socket_view
    |> Atom.to_string()
    |> String.replace("Elixir.MemorexWeb.", "")
    |> Macro.underscore()
    |> String.replace("_", "-")
    |> String.replace("/", "-")
    |> String.downcase()
  end

  @spec format_datetime(nil | DateTime.t()) :: String.t()
  def format_datetime(nil), do: "-"

  def format_datetime(%DateTime{} = datetime) do
    # See: https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Strftime.html
    datetime |> TimeUtils.to_timezone() |> Timex.format!("%a, %b %e, %Y, %l:%M %P", :strftime)
  end

  @spec ease_factor(float() | nil) :: String.t()
  def ease_factor(nil), do: "-"
  def ease_factor(ease_factor), do: :erlang.float_to_binary(ease_factor, decimals: 3)

  @spec format_iso_datetime(nil | DateTime.t()) :: String.t()
  def format_iso_datetime(nil), do: "-"

  def format_iso_datetime(%DateTime{} = datetime) do
    # See: https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Strftime.html
    datetime |> TimeUtils.to_timezone() |> Timex.format!("%Y-%m-%d %I:%M %P (%a)", :strftime)
  end

  @spec strip_off_seconds(String.t()) :: String.t()
  defp strip_off_seconds(formatted_time), do: String.replace(formatted_time, ~r/, \d* seconds/, "")

  @spec strip_off_milliseconds(String.t()) :: String.t()
  defp strip_off_milliseconds(formatted_time), do: String.replace(formatted_time, ~r/, \d*.\d* milliseconds/, "")

  @spec zero_microseconds_to_now(String.t()) :: String.t()
  defp zero_microseconds_to_now(formatted_time), do: String.replace(formatted_time, "0 microseconds", "Now")
end

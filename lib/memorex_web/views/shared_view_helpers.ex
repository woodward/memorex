defmodule MemorexWeb.SharedViewHelpers do
  @moduledoc false

  use Phoenix.HTML

  alias Timex.Duration

  @spec format(Duration.t() | DateTime.t() | nil) :: String.t()
  def format(nil), do: "-"
  def format(%Duration{} = duration), do: Timex.Format.Duration.Formatters.Humanized.format(duration)

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
end

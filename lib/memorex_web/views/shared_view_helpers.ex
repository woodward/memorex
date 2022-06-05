defmodule MemorexWeb.SharedViewHelpers do
  @moduledoc false

  use Phoenix.HTML

  alias Timex.Duration

  @spec format(Duration.t() | DateTime.t() | nil) :: String.t()
  def format(nil), do: "-"
  def format(%Duration{} = duration), do: Timex.Format.Duration.Formatters.Humanized.format(duration)

  def truncate(text, options \\ []) do
    # From: https://github.com/ikeikeikeike/phoenix_html_simplified_helpers/blob/master/lib/phoenix_html_simplified_helpers/truncate.ex#L2
    len = options[:length] || 30
    omi = options[:omission] || "..."

    cond do
      !String.valid?(text) ->
        text

      String.length(text) < len ->
        text

      true ->
        len_with_omi = len - String.length(omi)

        stop =
          if options[:separator] do
            rindex(text, options[:separator], len_with_omi) || len_with_omi
          else
            len_with_omi
          end

        "#{String.slice(text, 0, stop)}#{omi}"
    end
  end

  defp rindex(text, str, offset) do
    text =
      if offset do
        String.slice(text, 0, offset)
      else
        text
      end

    revesed = text |> String.reverse()
    matchword = String.reverse(str)

    case :binary.match(revesed, matchword) do
      {at, strlen} ->
        String.length(text) - at - strlen

      :nomatch ->
        nil
    end
  end

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

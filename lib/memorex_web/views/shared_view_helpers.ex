defmodule MemorexWeb.SharedViewHelpers do
  @moduledoc false

  use Phoenix.HTML

  alias Timex.Duration

  @spec format(Duration.t() | DateTime.t()) :: String.t()
  def format(%Duration{} = duration), do: Timex.Format.Duration.Formatters.Humanized.format(duration)
end

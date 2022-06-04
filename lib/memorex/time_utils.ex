defmodule Memorex.TimeUtils do
  @moduledoc false

  @spec now :: DateTime.t()
  def now, do: Application.get_env(:memorex, :timezone) |> Timex.now()
end

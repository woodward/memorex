defmodule Memorex.ConfigFile do
  @moduledoc false

  @spec read(String.t()) :: map()
  def read(filename) do
    filename |> File.read!() |> Toml.decode() |> elem(1)
  end
end

defmodule Memorex.Ecto.TimexDuration do
  @moduledoc false

  # See: https://hexdocs.pm/ecto/Ecto.Type.html
  use Ecto.Type

  alias Timex.Duration

  @impl Ecto.Type
  def type, do: :integer

  @impl Ecto.Type
  def cast(duration) when is_integer(duration) do
    {:ok, Duration.from_seconds(duration)}
  end

  def cast(%Duration{} = duration), do: {:ok, duration}
  def cast(_), do: :error

  @impl Ecto.Type
  def load(data) when is_integer(data) do
    {:ok, Duration.from_seconds(data)}
  end

  @impl Ecto.Type
  def equal?(nil, _duration2), do: false
  def equal?(_duration1, nil), do: false

  def equal?(duration1, duration2) do
    Duration.to_seconds(duration1) == Duration.to_seconds(duration2)
  end

  @impl Ecto.Type
  def dump(%Duration{} = duration), do: {:ok, Duration.to_seconds(duration, truncate: true)}
  def dump(_), do: :error
end

defmodule Memorex.TimeUtils do
  @moduledoc false

  @spec to_timezone(DateTime.t(), Calendar.time_zone()) :: DateTime.t()
  def to_timezone(datetime, tz \\ timezone()), do: Timex.Timezone.convert(datetime, tz)

  @spec now :: DateTime.t()
  def now, do: timezone() |> Timex.now()

  @spec timezone() :: Calendar.time_zone()
  def timezone, do: Application.get_env(:memorex, Memorex.Scheduler.Config)[:timezone]
end

defmodule Memorex.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Memorex.Ecto.Repo,
      MemorexWeb.Telemetry,
      {Phoenix.PubSub, name: Memorex.PubSub},
      MemorexWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Memorex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    MemorexWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

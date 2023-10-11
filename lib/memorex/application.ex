defmodule Memorex.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MemorexWeb.Telemetry,
      Memorex.Ecto.Repo,
      {DNSCluster, query: Application.get_env(:memorex, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Memorex.PubSub},
      # Start a worker by calling: Memorex.Worker.start_link(arg)
      # {Memorex.Worker, arg},
      # Start to serve requests, typically the last entry
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

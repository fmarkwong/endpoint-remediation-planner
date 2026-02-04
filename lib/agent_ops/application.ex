defmodule AgentOps.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc """
  Application supervision tree for AgentOps.
  """

  use Application

  @impl true
  @spec start(Application.start_type(), term()) :: Supervisor.on_start()
  def start(_type, _args) do
    children = [
      AgentOpsWeb.Telemetry,
      AgentOps.Repo,
      {Oban, Application.fetch_env!(:agent_ops, Oban)},
      {DNSCluster, query: Application.get_env(:agent_ops, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AgentOps.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: AgentOps.Finch},
      # Start a worker by calling: AgentOps.Worker.start_link(arg)
      # {AgentOps.Worker, arg},
      # Start to serve requests, typically the last entry
      AgentOpsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AgentOps.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  @spec config_change(keyword(), keyword(), keyword()) :: :ok
  def config_change(changed, _new, removed) do
    AgentOpsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

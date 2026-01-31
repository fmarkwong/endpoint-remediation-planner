defmodule AgentOps.Repo do
  use Ecto.Repo,
    otp_app: :agent_ops,
    adapter: Ecto.Adapters.Postgres
end

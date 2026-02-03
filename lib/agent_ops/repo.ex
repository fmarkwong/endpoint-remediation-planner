defmodule AgentOps.Repo do
  @moduledoc """
  Ecto repository for database access.
  """
  use Ecto.Repo,
    otp_app: :agent_ops,
    adapter: Ecto.Adapters.Postgres
end

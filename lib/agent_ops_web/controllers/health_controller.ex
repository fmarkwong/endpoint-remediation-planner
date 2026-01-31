defmodule AgentOpsWeb.HealthController do
  use AgentOpsWeb, :controller

  def index(conn, _params) do
    json(conn, %{ok: true})
  end
end

defmodule AgentOpsWeb.HealthController do
  @moduledoc """
  Simple health check endpoint.
  """
  use AgentOpsWeb, :controller

  def index(conn, _params) do
    json(conn, %{ok: true})
  end
end

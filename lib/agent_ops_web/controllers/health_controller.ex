defmodule AgentOpsWeb.HealthController do
  @moduledoc """
  Simple health check endpoint.
  """
  use AgentOpsWeb, :controller

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    json(conn, %{ok: true})
  end
end

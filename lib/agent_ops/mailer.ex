defmodule AgentOps.Mailer do
  @moduledoc """
  Swoosh mailer configuration entrypoint.
  """
  use Swoosh.Mailer, otp_app: :agent_ops
end

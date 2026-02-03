defmodule AgentOps.Observability.Log do
  @moduledoc """
  Structured logging helpers for run/step metadata.
  """

  require Logger

  def info(run_id, step_id, message, meta \\ %{}) do
    with_metadata(run_id, step_id, meta, fn -> Logger.info(message) end)
  end

  def error(run_id, step_id, message, meta \\ %{}) do
    with_metadata(run_id, step_id, meta, fn -> Logger.error(message) end)
  end

  defp with_metadata(run_id, step_id, meta, fun) do
    previous = Logger.metadata()

    Logger.metadata(run_id: run_id, step_id: step_id)

    case meta do
      %{} -> Logger.metadata(meta)
      _ -> :ok
    end

    try do
      fun.()
    after
      Logger.reset_metadata()
      Logger.metadata(previous)
    end
  end
end

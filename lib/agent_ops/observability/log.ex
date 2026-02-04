defmodule AgentOps.Observability.Log do
  @moduledoc """
  Structured logging helpers for run/step metadata.
  """

  require Logger

  @spec info(integer() | nil, integer() | nil, String.t(), map()) :: :ok
  def info(run_id, step_id, message, meta \\ %{}) do
    with_metadata(run_id, step_id, meta, fn -> Logger.info(message) end)
  end

  @spec error(integer() | nil, integer() | nil, String.t(), map()) :: :ok
  def error(run_id, step_id, message, meta \\ %{}) do
    with_metadata(run_id, step_id, meta, fn -> Logger.error(message) end)
  end

  defp with_metadata(run_id, step_id, meta, fun) do
    previous = Logger.metadata()

    Logger.metadata(run_id: run_id, step_id: step_id)

    meta
    |> Enum.into([])
    |> Logger.metadata()

    try do
      fun.()
    after
      Logger.reset_metadata()
      Logger.metadata(previous)
    end
  end
end

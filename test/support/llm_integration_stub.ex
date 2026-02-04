defmodule AgentOps.LLM.RunnerIntegrationStub do
  @moduledoc """
  Stub LLM client for integration tests with configurable investigation/proposal payloads.
  """

  @behaviour AgentOps.LLM.Client

  def complete(prompt, _opts) do
    response = pick_response(prompt)
    {:ok, %{content: response, usage: %{}}}
  end

  defp pick_response(prompt) do
    case {String.contains?(prompt, "hypothesis"), investigation_raw(), investigation_repair_raw()} do
      {true, nil, _} ->
        Jason.encode!(investigation())

      {true, raw, nil} ->
        raw

      {true, raw, repair_raw} ->
        if String.contains?(prompt, "Return valid JSON only"), do: repair_raw, else: raw

      {false, _, _} ->
        Jason.encode!(proposal())
    end
  end

  defp investigation do
    case Process.get({__MODULE__, :investigation}) do
      nil -> %{}
      investigation -> investigation
    end
  end

  defp proposal do
    case Process.get({__MODULE__, :proposal}) do
      nil -> %{}
      proposal -> proposal
    end
  end

  defp investigation_raw do
    Process.get({__MODULE__, :investigation_raw})
  end

  defp investigation_repair_raw do
    Process.get({__MODULE__, :investigation_repair_raw})
  end
end

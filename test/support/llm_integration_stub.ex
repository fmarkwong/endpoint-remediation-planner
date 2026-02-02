defmodule AgentOps.LLM.RunnerIntegrationStub do
  @moduledoc false

  @behaviour AgentOps.LLM.Client

  def complete(prompt, _opts) do
    response = pick_response(prompt)
    {:ok, %{content: response, usage: %{}}}
  end

  defp pick_response(prompt) do
    case {String.contains?(prompt, "hypothesis"), plan_raw(), plan_repair_raw()} do
      {true, nil, _} -> Jason.encode!(plan())
      {true, raw, nil} -> raw
      {true, raw, repair_raw} -> if String.contains?(prompt, "Return valid JSON only"), do: repair_raw, else: raw
      {false, _, _} -> Jason.encode!(proposal())
    end
  end

  defp plan do
    case Process.get({__MODULE__, :plan}) do
      nil -> %{}
      plan -> plan
    end
  end

  defp proposal do
    case Process.get({__MODULE__, :proposal}) do
      nil -> %{}
      proposal -> proposal
    end
  end

  defp plan_raw do
    Process.get({__MODULE__, :plan_raw})
  end

  defp plan_repair_raw do
    Process.get({__MODULE__, :plan_repair_raw})
  end
end

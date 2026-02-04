defmodule AgentOps.LLM.TestRunnerStub do
  @moduledoc """
  Stub LLM client for runner job tests with deterministic investigation/proposal outputs.
  """

  @behaviour AgentOps.LLM.Client

  def complete(prompt, _opts) do
    endpoint_ids = Process.get({__MODULE__, :endpoint_ids}, [])

    if String.contains?(prompt, "hypothesis") do
      {:ok,
       %{
         content:
           Jason.encode!(%{
             "hypothesis" => "gupdate disabled",
             "steps" => [
               %{
                 "tool" => "get_installed_software",
                 "input" => %{"endpoint_ids" => endpoint_ids}
               },
               %{
                 "tool" => "get_service_status",
                 "input" => %{"endpoint_ids" => endpoint_ids, "service_name" => "gupdate"}
               }
             ],
             "stop_conditions" => ["service running"],
             "risk_level" => "low"
           }),
         usage: %{}
       }}
    else
      {:ok,
       %{
         content:
           Jason.encode!(%{
             "summary" => "gupdate disabled",
             "findings" => ["service disabled"],
             "remediation" => %{
               "template_id" => "enable_windows_service",
               "params" => %{"service" => "gupdate"},
               "confidence" => 0.8
             }
           }),
         usage: %{}
       }}
    end
  end
end

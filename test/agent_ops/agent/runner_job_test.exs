defmodule AgentOps.Agent.RunnerJobTest do
  use AgentOps.DataCase, async: true

  alias AgentOps.Agent.RunnerJob

  test "perform executes run" do
    stub_llm()

    {:ok, run} =
      AgentOps.create_agent_run(%{
        input: "Chrome updates failing",
        mode: :propose,
        state: %{"endpoint_ids" => []}
      })

    {:ok, _} = RunnerJob.perform(%Oban.Job{args: %{"run_id" => run.id}})
    steps = AgentOps.list_agent_steps_for_run(run.id)

    assert Enum.any?(steps, &(&1.step_type == :plan))
    assert Enum.any?(steps, &(&1.step_type == :proposal))
  end

  defp stub_llm do
    Code.eval_string("""
      defmodule AgentOps.LLM.TestRunnerStub do
        @behaviour AgentOps.LLM.Client

        def complete(prompt, _opts) do
          if String.contains?(prompt, "hypothesis") do
            {:ok, %{content: Jason.encode!(%{
              \"hypothesis\" => \"gupdate disabled\",
              \"steps\" => [
                %{\"tool\" => \"get_installed_software\", \"input\" => %{\"endpoint_ids\" => []}},
                %{\"tool\" => \"get_service_status\", \"input\" => %{\"endpoint_ids\" => [], \"service_name\" => \"gupdate\"}}
              ],
              \"stop_conditions\" => [\"service running\"],
              \"risk_level\" => \"low\"
            }), usage: %{}}}
          else
            {:ok, %{content: Jason.encode!(%{
              \"summary\" => \"gupdate disabled\",
              \"findings\" => [\"service disabled\"],
              \"remediation\" => %{
                \"template_id\" => \"enable_windows_service\",
                \"params\" => %{\"service\" => \"gupdate\"},
                \"confidence\" => 0.8
              }
            }), usage: %{}}}
          end
        end
      end
    """)

    Application.put_env(:agent_ops, :llm_provider, AgentOps.LLM.TestRunnerStub)
  end
end

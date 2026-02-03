defmodule AgentOps.Agent.RunnerJobTest do
  use AgentOps.DataCase, async: false

  alias AgentOps.Agent.RunnerJob

  test "perform executes run" do
    stub_llm()

    endpoint =
      %AgentOps.Endpoint{}
      |> AgentOps.Endpoint.changeset(%{hostname: "test-1"})
      |> AgentOps.Repo.insert!()

    Process.put({AgentOps.LLM.TestRunnerStub, :endpoint_ids}, [endpoint.id])

    {:ok, run} =
      AgentOps.create_agent_run(%{
        input: "Chrome updates failing",
        mode: :propose,
        state: %{"endpoint_ids" => [endpoint.id]}
      })

    {:ok, _} = RunnerJob.perform(%Oban.Job{args: %{"run_id" => run.id}})
    steps = AgentOps.list_agent_steps_for_run(run.id)

    assert Enum.any?(steps, &(&1.step_type == :plan))
    assert Enum.any?(steps, &(&1.step_type == :proposal))

    Process.delete({AgentOps.LLM.TestRunnerStub, :endpoint_ids})
  end

  defp stub_llm do
    Application.put_env(:agent_ops, :llm_provider, AgentOps.LLM.TestRunnerStub)
  end
end

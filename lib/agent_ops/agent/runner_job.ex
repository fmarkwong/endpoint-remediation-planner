defmodule AgentOps.Agent.RunnerJob do
  use Oban.Worker, queue: :agent_runs

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"run_id" => run_id}}) do
    AgentOps.Agent.Runner.run(run_id)
  end
end

defmodule AgentOps.Agent.RunnerJob do
  @moduledoc """
  Oban job that executes a single AgentRun by delegating to the runner.
  """
  use Oban.Worker, queue: :agent_runs

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok | {:ok, :succeeded} | {:error, term()}
  def perform(%Oban.Job{args: %{"run_id" => run_id}}) do
    AgentOps.Agent.Runner.run(run_id)
  end
end

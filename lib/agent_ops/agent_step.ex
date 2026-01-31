defmodule AgentOps.AgentStep do
  use Ecto.Schema
  import Ecto.Changeset

  @step_types [:plan, :tool_call, :observation, :proposal, :final, :error]

  schema "agent_steps" do
    field :step_type, Ecto.Enum, values: @step_types
    field :input, :map
    field :output, :map
    field :error, :string
    field :latency_ms, :integer
    field :token_usage, :map

    belongs_to :agent_run, AgentOps.AgentRun

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(agent_step, attrs) do
    agent_step
    |> cast(attrs, [:agent_run_id, :step_type, :input, :output, :error, :latency_ms, :token_usage])
    |> validate_required([:agent_run_id, :step_type])
  end

  def step_types, do: @step_types
end

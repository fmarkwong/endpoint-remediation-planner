defmodule AgentOps.AgentStep do
  @moduledoc """
  Schema for a single step in an agent run timeline.
  """

  @type t :: %__MODULE__{}
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :step_type,
             :input,
             :output,
             :error,
             :latency_ms,
             :token_usage,
             :agent_run_id,
             :inserted_at
           ]}

  @step_types [:investigate, :tool_call, :observation, :proposal, :final, :error]

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

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(agent_step, attrs) do
    agent_step
    |> cast(attrs, [:agent_run_id, :step_type, :input, :output, :error, :latency_ms, :token_usage])
    |> validate_required([:agent_run_id, :step_type])
  end

  @spec step_types() :: [atom()]
  def step_types, do: @step_types
end

defmodule AgentOps.AgentRun do
  use Ecto.Schema
  import Ecto.Changeset

  @modes [:analyze_only, :propose]
  @statuses [:queued, :running, :succeeded, :failed]

  schema "agent_runs" do
    field :input, :string
    field :mode, Ecto.Enum, values: @modes, default: :propose
    field :status, Ecto.Enum, values: @statuses, default: :queued
    field :state, :map
    field :llm_provider, :string
    field :llm_model, :string
    field :prompt_version, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(agent_run, attrs) do
    agent_run
    |> cast(attrs, [:input, :mode, :status, :state, :llm_provider, :llm_model, :prompt_version])
    |> validate_required([:input, :mode, :status])
  end

  def modes, do: @modes
  def statuses, do: @statuses
end

defmodule AgentOps.AgentRun do
  @moduledoc """
  Schema for a single remediation run and its persisted state.
  """

  @type t :: %__MODULE__{}
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :input,
             :mode,
             :status,
             :state,
             :llm_provider,
             :llm_model,
             :prompt_version,
             :inserted_at,
             :updated_at
           ]}

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

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(agent_run, attrs) do
    agent_run
    |> cast(attrs, [:input, :mode, :status, :state, :llm_provider, :llm_model, :prompt_version])
    |> validate_required([:input, :mode, :status])
  end

  @spec modes() :: [atom()]
  def modes, do: @modes

  @spec statuses() :: [atom()]
  def statuses, do: @statuses
end

defmodule AgentOps.Repo.Migrations.CreateAgentRuns do
  use Ecto.Migration

  def change do
    create table(:agent_runs) do
      add :input, :text, null: false
      add :mode, :string, null: false, default: "propose"
      add :status, :string, null: false, default: "queued"
      add :state, :map
      add :llm_provider, :string
      add :llm_model, :string
      add :prompt_version, :string

      timestamps(type: :utc_datetime)
    end
  end
end

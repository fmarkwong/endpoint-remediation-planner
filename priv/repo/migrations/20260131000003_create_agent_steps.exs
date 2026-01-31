defmodule AgentOps.Repo.Migrations.CreateAgentSteps do
  use Ecto.Migration

  def change do
    create table(:agent_steps) do
      add :agent_run_id, references(:agent_runs, on_delete: :delete_all), null: false
      add :step_type, :string, null: false
      add :input, :map
      add :output, :map
      add :error, :text
      add :latency_ms, :integer
      add :token_usage, :map

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:agent_steps, [:agent_run_id])
  end
end

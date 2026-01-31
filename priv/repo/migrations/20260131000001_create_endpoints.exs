defmodule AgentOps.Repo.Migrations.CreateEndpoints do
  use Ecto.Migration

  def change do
    create table(:endpoints) do
      add :hostname, :string, null: false
      add :os_version, :string
      add :installed_software, :map
      add :services, :map
      add :last_seen_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end

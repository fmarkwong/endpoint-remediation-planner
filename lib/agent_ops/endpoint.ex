defmodule AgentOps.Endpoint do
  @moduledoc """
  Schema representing a managed endpoint and its inventory data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "endpoints" do
    field :hostname, :string
    field :os_version, :string
    field :installed_software, :map
    field :services, :map
    field :last_seen_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(endpoint, attrs) do
    endpoint
    |> cast(attrs, [:hostname, :os_version, :installed_software, :services, :last_seen_at])
    |> validate_required([:hostname])
  end
end

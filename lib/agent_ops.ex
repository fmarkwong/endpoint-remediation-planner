defmodule AgentOps do
  @moduledoc """
  AgentOps keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  import Ecto.Query, warn: false

  alias AgentOps.Repo
  alias AgentOps.Endpoint
  alias AgentOps.AgentRun
  alias AgentOps.AgentStep

  @spec list_endpoints() :: [Endpoint.t()]
  def list_endpoints do
    Repo.all(Endpoint)
  end

  @spec get_endpoint!(integer()) :: Endpoint.t()
  def get_endpoint!(id), do: Repo.get!(Endpoint, id)

  @spec create_endpoint(map()) :: {:ok, Endpoint.t()} | {:error, Ecto.Changeset.t()}
  def create_endpoint(attrs) do
    %Endpoint{}
    |> Endpoint.changeset(attrs)
    |> Repo.insert()
  end

  @spec list_endpoints_by_ids([integer()]) :: [Endpoint.t()]
  def list_endpoints_by_ids(ids) when is_list(ids) do
    Endpoint
    |> where([e], e.id in ^ids)
    |> Repo.all()
  end

  @spec get_agent_run!(integer()) :: AgentRun.t()
  def get_agent_run!(id), do: Repo.get!(AgentRun, id)

  @spec get_agent_run(integer()) :: AgentRun.t() | nil
  def get_agent_run(id), do: Repo.get(AgentRun, id)

  @spec create_agent_run(map()) :: {:ok, AgentRun.t()} | {:error, Ecto.Changeset.t()}
  def create_agent_run(attrs) do
    %AgentRun{}
    |> AgentRun.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_agent_run(AgentRun.t(), map()) ::
          {:ok, AgentRun.t()} | {:error, Ecto.Changeset.t()}
  def update_agent_run(%AgentRun{} = agent_run, attrs) do
    agent_run
    |> AgentRun.changeset(attrs)
    |> Repo.update()
  end

  @spec list_agent_steps_for_run(integer()) :: [AgentStep.t()]
  def list_agent_steps_for_run(agent_run_id) do
    AgentStep
    |> where([s], s.agent_run_id == ^agent_run_id)
    |> order_by([s], asc: s.inserted_at)
    |> Repo.all()
  end

  @spec create_agent_step(map()) :: {:ok, AgentStep.t()} | {:error, Ecto.Changeset.t()}
  def create_agent_step(attrs) do
    %AgentStep{}
    |> AgentStep.changeset(attrs)
    |> Repo.insert()
  end
end

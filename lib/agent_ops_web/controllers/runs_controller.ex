defmodule AgentOpsWeb.RunsController do
  use AgentOpsWeb, :controller

  alias AgentOps
  alias AgentOps.Agent.RunnerJob

  def create(conn, params) do
    input = Map.get(params, "input") || Map.get(params, :input)
    mode = Map.get(params, "mode") || Map.get(params, :mode) || "propose"
    endpoint_ids = Map.get(params, "endpoint_ids") || Map.get(params, :endpoint_ids)

    cond do
      not is_binary(input) or input == "" ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "input_required"})

      not is_binary(mode) ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "invalid_mode"})

      true ->
        resolved_ids = resolve_endpoint_ids(endpoint_ids)

        case AgentOps.create_agent_run(%{
               input: input,
               mode: mode,
               status: :queued,
               state: %{"endpoint_ids" => resolved_ids}
             }) do
          {:ok, run} ->
            {:ok, _job} = Oban.insert(RunnerJob.new(%{"run_id" => run.id}))

            conn
            |> put_status(:accepted)
            |> json(%{run_id: run.id, status: "queued"})

          {:error, _changeset} ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: "invalid_run"})
        end
    end
  end

  def show(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {run_id, ""} ->
        case AgentOps.get_agent_run(run_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "not_found"})

          run ->
            steps = AgentOps.list_agent_steps_for_run(run_id)

            conn
            |> put_status(:ok)
            |> json(%{run: run, steps: steps})
        end

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "invalid_id"})
    end
  end

  defp resolve_endpoint_ids(nil), do: default_endpoint_ids()

  defp resolve_endpoint_ids(endpoint_ids) when is_list(endpoint_ids) do
    ids = Enum.filter(endpoint_ids, &is_integer/1)
    if ids == [], do: default_endpoint_ids(), else: ids
  end

  defp resolve_endpoint_ids(_), do: default_endpoint_ids()

  defp default_endpoint_ids do
    AgentOps.list_endpoints()
    |> Enum.take(3)
    |> Enum.map(& &1.id)
  end
end

defmodule AgentOpsWeb.RunsControllerTest do
  use AgentOpsWeb.ConnCase, async: true

  alias AgentOps
  alias AgentOps.Endpoint
  alias AgentOps.Repo

  setup do
    endpoints =
      Enum.map(1..3, fn idx ->
        %Endpoint{}
        |> Endpoint.changeset(%{hostname: "test-#{idx}"})
        |> Repo.insert!()
      end)

    %{endpoint_ids: Enum.map(endpoints, & &1.id)}
  end

  test "POST /api/runs enqueues a run", %{conn: conn, endpoint_ids: endpoint_ids} do
    payload = %{
      "input" => "Investigate endpoints",
      "endpoint_ids" => endpoint_ids,
      "mode" => "propose"
    }

    conn = post(conn, ~p"/api/runs", payload)

    assert %{"run_id" => run_id, "status" => "queued"} = json_response(conn, 202)
    assert AgentOps.get_agent_run!(run_id)
  end

  test "GET /api/runs/:id returns run with steps", %{conn: conn} do
    {:ok, run} =
      AgentOps.create_agent_run(%{
        input: "Investigate",
        mode: :propose,
        status: :queued,
        state: %{"endpoint_ids" => []}
      })

    AgentOps.create_agent_step(%{agent_run_id: run.id, step_type: :plan, output: %{"ok" => true}})

    conn = get(conn, ~p"/api/runs/#{run.id}")
    response = json_response(conn, 200)

    run_id = run.id
    assert %{"run" => %{"id" => ^run_id}, "steps" => steps} = response
    assert length(steps) == 1
  end

  test "POST /api/runs rejects missing input", %{conn: conn} do
    conn = post(conn, ~p"/api/runs", %{})
    assert %{"error" => "input_required"} = json_response(conn, 400)
  end
end

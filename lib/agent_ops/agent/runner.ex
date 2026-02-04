defmodule AgentOps.Agent.Runner do
  @moduledoc """
  Orchestrates a single remediation run by planning, executing tools,
  and optionally proposing a remediation.

  Runs are fail-closed: any error records an error step and marks the run failed.
  """

  alias AgentOps
  alias AgentOps.AgentRun
  alias AgentOps.Agent.Prompts
  alias AgentOps.Agent.Validators
  alias AgentOps.LLM.Client
  alias AgentOps.Observability.Log
  alias AgentOps.Repo
  alias AgentOps.Tools.Registry
  alias AgentOps.Tools.Scripts

  import Ecto.Query, warn: false

  @max_steps 5

  @spec run(integer()) :: :ok | {:ok, :succeeded} | {:error, term()}
  def run(run_id) when is_integer(run_id) do
    run = AgentOps.get_agent_run!(run_id)

    case run.status do
      status when status in [:succeeded, :failed] ->
        :ok

      :running ->
        :ok

      :queued ->
        case start_run(run) do
          :ok ->
            state = run.state || %{}
            endpoint_ids = state["endpoint_ids"] || state[:endpoint_ids] || []

            with {:ok, plan} <- maybe_plan(run, endpoint_ids),
                 {:ok, observations} <- execute_steps(run, plan),
                 {:ok, _proposal} <- maybe_propose(run, observations, endpoint_ids) do
              AgentOps.create_agent_step(%{
                agent_run_id: run.id,
                step_type: :final,
                output: %{"status" => "succeeded"}
              })

              AgentOps.update_agent_run(run, %{status: :succeeded})
              {:ok, :succeeded}
            else
              {:error, reason} ->
                AgentOps.create_agent_step(%{
                  agent_run_id: run.id,
                  step_type: :error,
                  error: inspect(reason)
                })

                AgentOps.update_agent_run(run, %{status: :failed})
                {:error, reason}
            end

          :already_started ->
            :ok
        end
    end
  end

  @spec run(term()) :: {:error, :invalid_run_id}
  def run(_run_id), do: {:error, :invalid_run_id}

  defp maybe_plan(run, endpoint_ids) do
    state = run.state || %{}

    if state["plan"] do
      {:ok, state["plan"]}
    else
      tool_allowlist = Registry.allowlist()
      endpoint_tools = Registry.endpoint_tools()

      prompt =
        Prompts.planner_prompt(run.input, endpoint_ids) <>
          "\nAllowed tools: " <> Enum.join(tool_allowlist, ", ") <> "\nUse only these tools."

      repair_fun = fn instruction ->
        Client.complete(prompt <> "\n" <> instruction, temperature: 0)
        |> extract_content()
      end

      started_at = System.monotonic_time(:millisecond)

      with {:ok, %{content: content, usage: usage}} <- Client.complete(prompt, temperature: 0),
           {:ok, plan} <-
             Validators.validate_plan(content,
               tool_allowlist: tool_allowlist,
               required_endpoint_tools: endpoint_tools,
               endpoint_ids: endpoint_ids,
               allowed_services: Scripts.allowed_services(),
               repair_fun: repair_fun
             ) do
        latency_ms = System.monotonic_time(:millisecond) - started_at

        AgentOps.create_agent_step(%{
          agent_run_id: run.id,
          step_type: :plan,
          output: plan,
          latency_ms: latency_ms,
          token_usage: usage
        })

        Log.info(run.id, nil, "planner completed", %{latency_ms: latency_ms})

        AgentOps.update_agent_run(run, %{state: Map.put(run.state || %{}, "plan", plan)})
        {:ok, plan}
      end
    end
  end

  defp start_run(run) do
    # Atomically claim queued runs to avoid duplicate processing.
    {count, _} =
      from(r in AgentRun, where: r.id == ^run.id and r.status == :queued)
      |> Repo.update_all(set: [status: :running])

    if count == 1, do: :ok, else: :already_started
  end

  defp execute_steps(run, %{"steps" => steps}) when is_list(steps) do
    steps
    |> Enum.take(@max_steps)
    |> Enum.reduce_while({:ok, []}, fn step, {:ok, acc} ->
      tool = Map.get(step, "tool")
      input = Map.get(step, "input") || %{}

      tool_call =
        AgentOps.create_agent_step(%{
          agent_run_id: run.id,
          step_type: :tool_call,
          input: %{"tool" => tool, "input" => input}
        })

      started_at = System.monotonic_time(:millisecond)

      case Registry.execute(tool, input) do
        {:ok, result} ->
          latency_ms = System.monotonic_time(:millisecond) - started_at

          AgentOps.create_agent_step(%{
            agent_run_id: run.id,
            step_type: :observation,
            output: %{"tool" => tool, "result" => result},
            latency_ms: latency_ms
          })

          Log.info(run.id, step_id(tool_call), "tool completed", %{
            tool: tool,
            latency_ms: latency_ms
          })

          {:cont, {:ok, acc ++ [%{"tool" => tool, "result" => result}]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp execute_steps(_run, _plan), do: {:error, :invalid_plan}

  defp maybe_propose(run, observations, endpoint_ids) do
    if run.mode == :analyze_only do
      {:ok, %{}}
    else
      observations_json = observations |> stringify_keys() |> Jason.encode!()
      template_allowlist = Scripts.list_templates() |> Enum.map(& &1.id)

      prompt =
        Prompts.proposer_prompt(run.input, observations_json, endpoint_ids) <>
          "\nAllowed templates: " <>
          Enum.join(template_allowlist, ", ") <>
          "\nUse only these template_id values."

      repair_fun = fn instruction ->
        Client.complete(prompt <> "\n" <> instruction, temperature: 0)
        |> extract_content()
      end

      started_at = System.monotonic_time(:millisecond)

      with {:ok, %{content: content, usage: usage}} <- Client.complete(prompt, temperature: 0),
           {:ok, proposal} <-
             Validators.validate_proposal(content,
               template_allowlist: template_allowlist,
               params_validator: &Scripts.validate_params/2,
               repair_fun: repair_fun
             ) do
        latency_ms = System.monotonic_time(:millisecond) - started_at

        AgentOps.create_agent_step(%{
          agent_run_id: run.id,
          step_type: :proposal,
          output: proposal,
          latency_ms: latency_ms,
          token_usage: usage
        })

        Log.info(run.id, nil, "proposer completed", %{latency_ms: latency_ms})

        {:ok, proposal}
      end
    end
  end

  defp extract_content({:ok, %{content: content}}), do: content
  defp extract_content(_), do: ""

  defp step_id({:ok, %{id: id}}), do: id
  defp step_id(_), do: nil

  defp stringify_keys(value) when is_list(value) do
    Enum.map(value, &stringify_keys/1)
  end

  defp stringify_keys(value) when is_map(value) do
    value
    |> Enum.map(fn {key, val} -> {to_string(key), stringify_keys(val)} end)
    |> Map.new()
  end

  defp stringify_keys(value), do: value
end

defmodule AgentOps.Agent.RunnerIntegrationTest do
  use AgentOps.DataCase, async: true

  alias AgentOps
  alias AgentOps.Agent.Runner

  test "happy path creates plan, tools, proposal, final" do
    stub_llm(%{
      plan: %{
        "hypothesis" => "gupdate disabled",
        "steps" => [
          %{"tool" => "get_installed_software", "input" => %{"endpoint_ids" => [1, 2, 3]}},
          %{"tool" => "get_service_status", "input" => %{"endpoint_ids" => [1, 2, 3], "service_name" => "gupdate"}}
        ],
        "stop_conditions" => ["service running"],
        "risk_level" => "low"
      },
      proposal: %{
        "summary" => "gupdate disabled",
        "findings" => ["service disabled"],
        "remediation" => %{
          "template_id" => "enable_windows_service",
          "params" => %{"service" => "gupdate"},
          "confidence" => 0.8
        }
      }
    })

    {:ok, run} =
      AgentOps.create_agent_run(%{
        input: "Chrome updates failing",
        mode: :propose,
        state: %{"endpoint_ids" => [1, 2, 3]}
      })

    {:ok, :succeeded} = Runner.run(run.id)

    steps = AgentOps.list_agent_steps_for_run(run.id)
    types = Enum.map(steps, & &1.step_type)

    assert :plan in types
    assert :proposal in types
    assert :final in types
  end

  test "unknown tool fails closed" do
    stub_llm(%{
      plan: %{
        "hypothesis" => "bad tool",
        "steps" => [%{"tool" => "nope", "input" => %{"endpoint_ids" => [1]}}],
        "stop_conditions" => [],
        "risk_level" => "low"
      },
      proposal: %{
        "summary" => "irrelevant",
        "findings" => ["x"],
        "remediation" => %{
          "template_id" => "enable_windows_service",
          "params" => %{"service" => "gupdate"},
          "confidence" => 0.5
        }
      }
    })

    {:ok, run} =
      AgentOps.create_agent_run(%{
        input: "Chrome updates failing",
        mode: :propose,
        state: %{"endpoint_ids" => [1]}
      })

    assert {:error, :unknown_tool} = Runner.run(run.id)

    steps = AgentOps.list_agent_steps_for_run(run.id)
    assert Enum.any?(steps, &(&1.step_type == :error))
  end

  test "invalid json triggers repair attempt then fails" do
    stub_llm(%{
      plan_raw: "{",
      plan_repair_raw: "{",
      proposal: %{
        "summary" => "irrelevant",
        "findings" => ["x"],
        "remediation" => %{
          "template_id" => "enable_windows_service",
          "params" => %{"service" => "gupdate"},
          "confidence" => 0.5
        }
      }
    })

    {:ok, run} =
      AgentOps.create_agent_run(%{
        input: "Chrome updates failing",
        mode: :propose,
        state: %{"endpoint_ids" => [1]}
      })

    assert {:error, :invalid_json} = Runner.run(run.id)

    steps = AgentOps.list_agent_steps_for_run(run.id)
    assert Enum.any?(steps, &(&1.step_type == :error))
  end

  defp stub_llm(opts) do
    plan = Map.get(opts, :plan)
    proposal = Map.get(opts, :proposal)
    plan_raw = Map.get(opts, :plan_raw)
    plan_repair_raw = Map.get(opts, :plan_repair_raw)

    Code.eval_string("""
      defmodule AgentOps.LLM.RunnerIntegrationStub do
        @behaviour AgentOps.LLM.Client

        def complete(prompt, _opts) do
          cond do
            String.contains?(prompt, "hypothesis") ->
              case {#{inspect(plan_raw)}, #{inspect(plan_repair_raw)}} do
                {nil, _} -> {:ok, %{content: #{inspect(Jason.encode!(plan))}, usage: %{}}}
                {raw, nil} -> {:ok, %{content: raw, usage: %{}}}
                {raw, repair_raw} ->
                  if String.contains?(prompt, "Return valid JSON only") do
                    {:ok, %{content: repair_raw, usage: %{}}}
                  else
                    {:ok, %{content: raw, usage: %{}}}
                  end
              end

            true ->
              {:ok, %{content: #{inspect(Jason.encode!(proposal))}, usage: %{}}}
          end
        end
      end
    """)

    Application.put_env(:agent_ops, :llm_provider, AgentOps.LLM.RunnerIntegrationStub)
  end
end

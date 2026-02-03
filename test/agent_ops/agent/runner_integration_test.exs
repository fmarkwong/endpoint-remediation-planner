defmodule AgentOps.Agent.RunnerIntegrationTest do
  use AgentOps.DataCase, async: false

  alias AgentOps
  alias AgentOps.Agent.Runner

  test "happy path creates plan, tools, proposal, final" do
    stub_llm(%{
      plan: %{
        "hypothesis" => "gupdate disabled",
        "steps" => [
          %{"tool" => "get_installed_software", "input" => %{"endpoint_ids" => [1, 2, 3]}},
          %{
            "tool" => "get_service_status",
            "input" => %{"endpoint_ids" => [1, 2, 3], "service_name" => "gupdate"}
          }
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

    Application.put_env(:agent_ops, :llm_provider, AgentOps.LLM.StubClient)
  end

  test "nil state does not crash" do
    stub_llm(%{
      plan: %{
        "hypothesis" => "no-op",
        "steps" => [],
        "stop_conditions" => [],
        "risk_level" => "low"
      },
      proposal: %{
        "summary" => "no-op",
        "findings" => ["no issues"],
        "remediation" => %{
          "template_id" => "enable_windows_service",
          "params" => %{"service" => "gupdate"},
          "confidence" => 0.6
        }
      }
    })

    {:ok, run} =
      AgentOps.create_agent_run(%{
        input: "Investigate",
        mode: :propose
      })

    assert {:ok, :succeeded} = Runner.run(run.id)

    steps = AgentOps.list_agent_steps_for_run(run.id)
    assert Enum.any?(steps, &(&1.step_type == :plan))
    assert Enum.any?(steps, &(&1.step_type == :proposal))
    assert Enum.any?(steps, &(&1.step_type == :final))

    Application.put_env(:agent_ops, :llm_provider, AgentOps.LLM.StubClient)
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

    Application.put_env(:agent_ops, :llm_provider, AgentOps.LLM.StubClient)
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

    Application.put_env(:agent_ops, :llm_provider, AgentOps.LLM.StubClient)
  end

  defp stub_llm(opts) do
    Process.put({AgentOps.LLM.RunnerIntegrationStub, :plan}, Map.get(opts, :plan))
    Process.put({AgentOps.LLM.RunnerIntegrationStub, :proposal}, Map.get(opts, :proposal))
    Process.put({AgentOps.LLM.RunnerIntegrationStub, :plan_raw}, Map.get(opts, :plan_raw))

    Process.put(
      {AgentOps.LLM.RunnerIntegrationStub, :plan_repair_raw},
      Map.get(opts, :plan_repair_raw)
    )

    Application.put_env(:agent_ops, :llm_provider, AgentOps.LLM.RunnerIntegrationStub)
  end
end

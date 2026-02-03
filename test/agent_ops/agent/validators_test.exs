defmodule AgentOps.Agent.ValidatorsTest do
  use ExUnit.Case, async: true

  alias AgentOps.Agent.Validators

  @tool_allowlist ["get_installed_software", "get_service_status"]
  @template_allowlist ["enable_windows_service", "reinstall_application"]

  test "validate_plan accepts valid plan" do
    json =
      Jason.encode!(%{
        "hypothesis" => "gupdate disabled",
        "steps" => [
          %{"tool" => "get_installed_software", "input" => %{"endpoint_ids" => [1, 2]}},
          %{
            "tool" => "get_service_status",
            "input" => %{"endpoint_ids" => [1, 2], "service_name" => "gupdate"}
          }
        ],
        "stop_conditions" => ["service running"],
        "risk_level" => "low"
      })

    assert {:ok, _} =
             Validators.validate_plan(json,
               tool_allowlist: @tool_allowlist,
               endpoint_ids: [1, 2, 3]
             )
  end

  test "validate_plan rejects unknown tool" do
    json =
      Jason.encode!(%{
        "hypothesis" => "unknown tool",
        "steps" => [%{"tool" => "nope", "input" => %{}}],
        "stop_conditions" => [],
        "risk_level" => "low"
      })

    assert {:error, :unknown_tool} =
             Validators.validate_plan(json, tool_allowlist: @tool_allowlist)
  end

  test "validate_plan rejects endpoint_ids outside run" do
    json =
      Jason.encode!(%{
        "hypothesis" => "out of scope",
        "steps" => [%{"tool" => "get_installed_software", "input" => %{"endpoint_ids" => [99]}}],
        "stop_conditions" => [],
        "risk_level" => "low"
      })

    assert {:error, :invalid_endpoint_ids} =
             Validators.validate_plan(json,
               tool_allowlist: @tool_allowlist,
               endpoint_ids: [1, 2, 3]
             )
  end

  test "validate_plan rejects invalid service_name" do
    json =
      Jason.encode!(%{
        "hypothesis" => "bad service",
        "steps" => [
          %{
            "tool" => "get_service_status",
            "input" => %{"endpoint_ids" => [1], "service_name" => "bits"}
          }
        ],
        "stop_conditions" => [],
        "risk_level" => "low"
      })

    assert {:error, :invalid_service_name} =
             Validators.validate_plan(json,
               tool_allowlist: @tool_allowlist,
               endpoint_ids: [1],
               allowed_services: ["gupdate", "wuauserv"]
             )
  end

  test "validate_plan repairs invalid json once" do
    repair_fun = fn _instruction ->
      Jason.encode!(%{
        "hypothesis" => "fixed",
        "steps" => [],
        "stop_conditions" => [],
        "risk_level" => "low"
      })
    end

    assert {:ok, _} = Validators.validate_plan("{", repair_fun: repair_fun)
  end

  test "validate_proposal accepts valid proposal" do
    json =
      Jason.encode!(%{
        "summary" => "gupdate disabled",
        "findings" => ["service disabled"],
        "remediation" => %{
          "template_id" => "enable_windows_service",
          "params" => %{"service" => "gupdate"},
          "confidence" => 0.8
        }
      })

    params_validator = fn template_id, params ->
      if template_id == "enable_windows_service" and params["service"] == "gupdate" do
        :ok
      else
        {:error, :invalid_params}
      end
    end

    assert {:ok, _} =
             Validators.validate_proposal(json,
               template_allowlist: @template_allowlist,
               params_validator: params_validator
             )
  end

  test "validate_proposal rejects unknown template" do
    json =
      Jason.encode!(%{
        "summary" => "bad template",
        "findings" => [],
        "remediation" => %{
          "template_id" => "nope",
          "params" => %{},
          "confidence" => 0.5
        }
      })

    assert {:error, :unknown_template} =
             Validators.validate_proposal(json, template_allowlist: @template_allowlist)
  end

  test "validate_proposal rejects invalid confidence" do
    json =
      Jason.encode!(%{
        "summary" => "bad confidence",
        "findings" => [],
        "remediation" => %{
          "template_id" => "enable_windows_service",
          "params" => %{"service" => "gupdate"},
          "confidence" => 1.5
        }
      })

    assert {:error, :invalid_confidence} =
             Validators.validate_proposal(json, template_allowlist: @template_allowlist)
  end
end

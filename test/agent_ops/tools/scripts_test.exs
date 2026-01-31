defmodule AgentOps.Tools.ScriptsTest do
  use ExUnit.Case, async: true

  alias AgentOps.Tools.Scripts

  test "list_templates returns required params" do
    templates = Scripts.list_templates()
    ids = Enum.map(templates, & &1.id)

    assert "enable_windows_service" in ids
    assert "reinstall_application" in ids
    assert "restart_service" in ids
  end

  test "valid_template? recognizes templates" do
    assert Scripts.valid_template?("enable_windows_service")
    refute Scripts.valid_template?("unknown")
  end

  test "validate_params accepts required fields" do
    assert :ok =
             Scripts.validate_params("enable_windows_service", %{"service" => "gupdate"})

    assert :ok = Scripts.validate_params("reinstall_application", %{"app_name" => "chrome"})
  end

  test "validate_params rejects missing or empty fields" do
    assert {:error, :invalid_params} = Scripts.validate_params("restart_service", %{})
    assert {:error, :invalid_params} =
             Scripts.validate_params("restart_service", %{"service" => ""})
  end

  test "validate_params rejects unknown templates" do
    assert {:error, :unknown_template} = Scripts.validate_params("nope", %{})
  end
end

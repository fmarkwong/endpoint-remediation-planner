defmodule AgentOps.Tools.RemediationTemplatesTest do
  use ExUnit.Case, async: true

  alias AgentOps.Tools.RemediationTemplates

  test "list_templates returns required params" do
    templates = RemediationTemplates.list_templates()
    ids = Enum.map(templates, & &1.id)

    assert "enable_windows_service" in ids
    assert "reinstall_application" in ids
    assert "restart_service" in ids
  end

  test "valid_template? recognizes templates" do
    assert RemediationTemplates.valid_template?("enable_windows_service")
    refute RemediationTemplates.valid_template?("unknown")
  end

  test "validate_params accepts required fields" do
    assert :ok =
             RemediationTemplates.validate_params("enable_windows_service", %{"service" => "gupdate"})

    assert :ok =
             RemediationTemplates.validate_params("reinstall_application", %{"app_name" => "chrome"})
  end

  test "validate_params rejects missing or empty fields" do
    assert {:error, :invalid_params} = RemediationTemplates.validate_params("restart_service", %{})

    assert {:error, :invalid_params} =
             RemediationTemplates.validate_params("restart_service", %{"service" => ""})
  end

  test "validate_params rejects invalid service values" do
    assert {:error, :invalid_params} =
             RemediationTemplates.validate_params("enable_windows_service", %{"service" => "chrome"})
  end

  test "validate_params rejects invalid app_name values" do
    assert {:error, :invalid_params} =
             RemediationTemplates.validate_params("reinstall_application", %{"app_name" => "firefox"})
  end

  test "validate_params rejects extra params" do
    assert {:error, :invalid_params} =
             RemediationTemplates.validate_params("enable_windows_service", %{
               "service" => "gupdate",
               "endpoints" => [1, 2]
             })
  end

  test "validate_params rejects unknown templates" do
    assert {:error, :unknown_template} = RemediationTemplates.validate_params("nope", %{})
  end
end

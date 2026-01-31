defmodule AgentOps.Tools.RegistryTest do
  use AgentOps.DataCase, async: true

  alias AgentOps.Endpoint
  alias AgentOps.Repo
  alias AgentOps.Tools.Registry

  test "execute returns error for unknown tool" do
    assert {:error, :unknown_tool} = Registry.execute("nope", %{})
  end

  test "execute returns installed software map" do
    endpoint =
      %Endpoint{}
      |> Endpoint.changeset(%{
        hostname: "win-300",
        installed_software: %{"chrome" => "119.0.0"}
      })
      |> Repo.insert!()

    {:ok, result} = Registry.execute("get_installed_software", %{endpoint_ids: [endpoint.id]})

    assert result == %{endpoint.id => %{"chrome" => "119.0.0"}}
  end

  test "execute returns error for invalid input" do
    assert {:error, :invalid_input} = Registry.execute("get_installed_software", "bad")
  end
end

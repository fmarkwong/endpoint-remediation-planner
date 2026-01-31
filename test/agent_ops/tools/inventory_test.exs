defmodule AgentOps.Tools.InventoryTest do
  use AgentOps.DataCase, async: true

  alias AgentOps.Endpoint
  alias AgentOps.Repo
  alias AgentOps.Tools.Inventory

  test "get_installed_software returns map keyed by endpoint id" do
    endpoint =
      %Endpoint{}
      |> Endpoint.changeset(%{
        hostname: "win-100",
        installed_software: %{"chrome" => "120.0.0"}
      })
      |> Repo.insert!()

    {:ok, result} = Inventory.get_installed_software(%{endpoint_ids: [endpoint.id]})

    assert result == %{endpoint.id => %{"chrome" => "120.0.0"}}
  end

  test "get_installed_software rejects invalid input" do
    assert {:error, :invalid_endpoint_ids} = Inventory.get_installed_software(%{})
  end

  test "get_service_status returns map keyed by endpoint id" do
    endpoint =
      %Endpoint{}
      |> Endpoint.changeset(%{
        hostname: "win-200",
        services: %{"gupdate" => "stopped"}
      })
      |> Repo.insert!()

    {:ok, result} =
      Inventory.get_service_status(%{endpoint_ids: [endpoint.id], service_name: "gupdate"})

    assert result == %{endpoint.id => "stopped"}
  end

  test "get_service_status rejects invalid service name" do
    endpoint =
      %Endpoint{}
      |> Endpoint.changeset(%{hostname: "win-201"})
      |> Repo.insert!()

    assert {:error, :invalid_service_name} =
             Inventory.get_service_status(%{endpoint_ids: [endpoint.id], service_name: ""})
  end
end

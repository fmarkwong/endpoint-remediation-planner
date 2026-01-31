defmodule AgentOps.Tools.Inventory do
  @moduledoc false

  import Ecto.Query, warn: false

  alias AgentOps.Endpoint
  alias AgentOps.Repo

  def get_installed_software(input) when is_map(input) do
    case extract_endpoint_ids(input) do
      {:ok, endpoint_ids} ->
        endpoints =
          Endpoint
          |> where([e], e.id in ^endpoint_ids)
          |> select([e], {e.id, e.installed_software})
          |> Repo.all()
          |> Map.new()

        result =
          Enum.reduce(endpoint_ids, %{}, fn id, acc ->
            Map.put(acc, id, Map.get(endpoints, id))
          end)

        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_installed_software(_input), do: {:error, :invalid_input}

  def get_service_status(input) when is_map(input) do
    with {:ok, endpoint_ids} <- extract_endpoint_ids(input),
         {:ok, service_name} <- extract_service_name(input) do
      endpoints =
        Endpoint
        |> where([e], e.id in ^endpoint_ids)
        |> select([e], {e.id, e.services})
        |> Repo.all()
        |> Map.new()

      result =
        Enum.reduce(endpoint_ids, %{}, fn id, acc ->
          services = Map.get(endpoints, id)
          Map.put(acc, id, service_status(services, service_name))
        end)

      {:ok, result}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_service_status(_input), do: {:error, :invalid_input}

  defp extract_endpoint_ids(input) do
    endpoint_ids = Map.get(input, :endpoint_ids) || Map.get(input, "endpoint_ids")

    cond do
      is_list(endpoint_ids) and Enum.all?(endpoint_ids, &is_integer/1) ->
        {:ok, endpoint_ids}

      true ->
        {:error, :invalid_endpoint_ids}
    end
  end

  defp extract_service_name(input) do
    service_name = Map.get(input, :service_name) || Map.get(input, "service_name")

    cond do
      is_binary(service_name) and byte_size(service_name) > 0 ->
        {:ok, service_name}

      true ->
        {:error, :invalid_service_name}
    end
  end

  defp service_status(nil, _service_name), do: nil

  defp service_status(services, service_name) when is_map(services) do
    Map.get(services, service_name)
  end

  defp service_status(_services, _service_name), do: nil
end

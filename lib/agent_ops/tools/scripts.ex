defmodule AgentOps.Tools.Scripts do
  @moduledoc """
  Remediation template registry and parameter validation.
  """

  @allowed_services ["gupdate", "wuauserv"]

  @templates %{
    "enable_windows_service" => %{required: ["service"], allowed: ["service"]},
    "reinstall_application" => %{required: ["app_name"], allowed: ["app_name"]},
    "restart_service" => %{required: ["service"], allowed: ["service"]}
  }

  @spec list_templates() :: [%{id: String.t(), required_params: [String.t()]}]
  def list_templates do
    Enum.map(@templates, fn {id, spec} ->
      %{id: id, required_params: spec.required}
    end)
  end

  @spec allowed_services() :: [String.t()]
  def allowed_services, do: @allowed_services

  @spec valid_template?(String.t()) :: boolean()
  def valid_template?(template_id) when is_binary(template_id) do
    Map.has_key?(@templates, template_id)
  end

  @spec valid_template?(term()) :: false
  def valid_template?(_template_id), do: false

  @spec validate_params(String.t(), map()) :: :ok | {:error, term()}
  def validate_params(template_id, params) when is_binary(template_id) and is_map(params) do
    case Map.get(@templates, template_id) do
      nil ->
        {:error, :unknown_template}

      %{required: required, allowed: allowed} ->
        param_keys = params |> Map.keys() |> Enum.map(&to_string/1)

        cond do
          not Enum.all?(required, &valid_param?(params, &1)) ->
            {:error, :invalid_params}

          Enum.any?(param_keys, fn key -> key not in allowed end) ->
            {:error, :invalid_params}

          template_id in ["enable_windows_service", "restart_service"] and
              not valid_service_param?(params) ->
            {:error, :invalid_params}

          template_id == "reinstall_application" and not valid_app_name_param?(params) ->
            {:error, :invalid_params}

          true ->
            :ok
        end
    end
  end

  @spec validate_params(term(), term()) :: {:error, :invalid_params}
  def validate_params(_template_id, _params), do: {:error, :invalid_params}

  defp valid_param?(params, key) do
    value = Map.get(params, key) || Map.get(params, String.to_atom(key))
    is_binary(value) and byte_size(value) > 0
  end

  defp valid_service_param?(params) do
    service = Map.get(params, "service") || Map.get(params, :service)
    is_binary(service) and service in @allowed_services
  end

  defp valid_app_name_param?(params) do
    app_name = Map.get(params, "app_name") || Map.get(params, :app_name)
    is_binary(app_name) and app_name == "chrome"
  end
end

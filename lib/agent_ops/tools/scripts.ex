defmodule AgentOps.Tools.Scripts do
  @moduledoc false

  @templates %{
    "enable_windows_service" => %{required: ["service"]},
    "reinstall_application" => %{required: ["app_name"]},
    "restart_service" => %{required: ["service"]}
  }

  def list_templates do
    Enum.map(@templates, fn {id, spec} ->
      %{id: id, required_params: spec.required}
    end)
  end

  def valid_template?(template_id) when is_binary(template_id) do
    Map.has_key?(@templates, template_id)
  end

  def valid_template?(_template_id), do: false

  def validate_params(template_id, params) when is_binary(template_id) and is_map(params) do
    case Map.get(@templates, template_id) do
      nil ->
        {:error, :unknown_template}

      %{required: required} ->
        if Enum.all?(required, &valid_param?(params, &1)) do
          :ok
        else
          {:error, :invalid_params}
        end
    end
  end

  def validate_params(_template_id, _params), do: {:error, :invalid_params}

  defp valid_param?(params, key) do
    value = Map.get(params, key) || Map.get(params, String.to_atom(key))
    is_binary(value) and byte_size(value) > 0
  end
end

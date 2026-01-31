defmodule AgentOps.Tools.Registry do
  @moduledoc false

  alias AgentOps.Tools.Inventory

  @tools %{
    "get_installed_software" => &Inventory.get_installed_software/1,
    "get_service_status" => &Inventory.get_service_status/1
  }

  def allowlist do
    Map.keys(@tools)
  end

  def execute(tool_name, input) when is_binary(tool_name) and is_map(input) do
    case Map.get(@tools, tool_name) do
      nil ->
        {:error, :unknown_tool}

      fun ->
        fun.(input)
    end
  end

  def execute(_tool_name, _input), do: {:error, :invalid_input}
end

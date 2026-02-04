defmodule AgentOps.Tools.Registry do
  @moduledoc """
  Registry for allowlisted inventory tools used by the investigator.
  """

  alias AgentOps.Tools.Inventory

  @tools %{
    "get_installed_software" => &Inventory.get_installed_software/1,
    "get_service_status" => &Inventory.get_service_status/1
  }

  @spec allowlist() :: [String.t()]
  def allowlist do
    Map.keys(@tools)
  end

  @spec endpoint_tools() :: [String.t()]
  def endpoint_tools do
    ["get_installed_software", "get_service_status"]
  end

  @spec execute(String.t(), map()) :: {:ok, term()} | {:error, term()}
  def execute(tool_name, input) when is_binary(tool_name) and is_map(input) do
    case Map.get(@tools, tool_name) do
      nil ->
        {:error, :unknown_tool}

      fun ->
        fun.(input)
    end
  end

  @spec execute(term(), term()) :: {:error, :invalid_input}
  def execute(_tool_name, _input), do: {:error, :invalid_input}
end

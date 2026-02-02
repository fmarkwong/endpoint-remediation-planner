defmodule AgentOps.Agent.Prompts do
  @moduledoc false

  @prompt_version "v1"

  def prompt_version, do: @prompt_version

  def planner_prompt(input, endpoint_ids) do
    endpoints = Enum.join(endpoint_ids, ", ")

    """
You are an expert sysadmin assistant. Return JSON only.

Input: #{input}
Endpoint IDs: [#{endpoints}]

Return JSON with keys: hypothesis (string), steps (array of objects), stop_conditions (array of strings), risk_level ("low" | "medium" | "high").
Each step object must include tool (string) and input (object) fields.
"""
  end

  def proposer_prompt(input, observations, endpoint_ids) do
    endpoints = Enum.join(endpoint_ids, ", ")

    """
You are an expert sysadmin assistant. Return JSON only.

Input: #{input}
Endpoint IDs: [#{endpoints}]
Observations: #{observations}

Return JSON with keys: summary (string), findings (array of strings), remediation (template_id, params, confidence).
Remediation fields: template_id (string), params (object), confidence (number 0 to 1).
"""
  end
end

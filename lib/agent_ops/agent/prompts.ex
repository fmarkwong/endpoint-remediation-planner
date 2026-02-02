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
If tool is get_service_status, input must include service_name (non-empty string).
service_name must be one of: gupdate, wuauserv.
All endpoint_ids in any step input must be a subset of the provided Endpoint IDs.
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
Allowed templates and required params:
- enable_windows_service: params {"service": "gupdate" | "wuauserv"}
- restart_service: params {"service": "gupdate" | "wuauserv"}
- reinstall_application: params {"app_name": "chrome"}
Do not include any extra params.
findings must always be a JSON array of strings, even if only one item.
When referring to services in findings or summary, use the exact service name (gupdate or wuauserv).
Example shape:
{
  "summary": "...",
  "findings": ["..."],
  "remediation": {
    "template_id": "enable_windows_service",
    "params": {"service": "gupdate"},
    "confidence": 0.8
  }
}
"""
  end
end

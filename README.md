# Endpoint Remediation Planner (AgentOps)

## Overview
Endpoint Remediation Planner is a safe, deterministic workflow that uses an LLM only for planning and proposing remediations. It is designed to help sysadmins and endpoint engineers investigate issues across fleets and draft consistent remediation recommendations without granting the model any execution capability. The system executes an allowlisted set of inventory tools against seeded endpoint data, validates all AI output, and stores an auditable timeline of steps in Postgres. No scripts are executed on endpoints.

An endpoint represents an individual managed machine (laptop, desktop, server, or VM) tracked by an endpoint management system. This project models those machines as database records with fields like hostname, OS version, installed software, service status, and last_seen_at. The intended workflow mirrors a sysadmin ticket: given a request like “Chrome updates failing on endpoints 1–3,” the system queries inventory, reasons over the results, and proposes a remediation—without executing anything on devices.

Inputs:
- A natural‑language request (input)
- Optional endpoint_ids (subset of seeded endpoints)
- Optional mode ("analyze_only" or "propose")

Outputs:
- A run record with status
- A step timeline containing:
  - plan (LLM‑generated investigation steps)
  - tool_call and observation steps (inventory results)
  - proposal (LLM‑suggested remediation template + params)
  - final (completion marker)
  - error (failure marker, only on failure)

example "proposal" step output:
```json
{
  "id": 98,
  "step_type": "proposal",
  "input": null,
  "output": {
    "findings": [
      "Endpoint 1 has the gupdate service stopped, preventing Chrome updates.",
      "Endpoint 2 has the gupdate service disabled, preventing Chrome updates.",
      "Endpoint 3 is running and has the latest version of Chrome."
    ],
    "remediation": {
      "confidence": 0.9,
      "params": {
        "service": "gupdate"
      },
      "template_id": "enable_windows_service"
    },
    "summary": "Chrome updates are failing on endpoints 1 and 2 due to service issues, while endpoint 3 is functioning normally."
  },
  "error": null,
  "latency_ms": 2866,
  "token_usage": {
    "completion_tokens": 124,
    "completion_tokens_details": {
      "accepted_prediction_tokens": 0,
      "audio_tokens": 0,
      "reasoning_tokens": 0,
      "rejected_prediction_tokens": 0
    },
    "prompt_tokens": 390,
    "prompt_tokens_details": {
      "audio_tokens": 0,
      "cached_tokens": 0
    },
    "total_tokens": 514
  },
  "agent_run_id": 27,
  "inserted_at": "2026-02-02T18:37:01Z"
}
```

## Quick setup
Prereqs: Elixir, Postgres, and a running Postgres server on localhost.

1) Install deps and set up the database:

mix deps.get
mix ecto.setup

2) Seed endpoint data (already included in ecto.setup, safe to run again):

mix run priv/repo/seeds.exs

3) Set your OpenAI API key (optional if you only run tests):

export OPENAI_API_KEY=your_key_here
export OPENAI_MODEL=gpt-4o-mini

## Demo
Open two terminals.

Terminal 1: start the server

mix phx.server

Terminal 2: create a run (copy/paste as a single line)

curl -i http://localhost:4000/api/runs \
  -H 'content-type: application/json' \
  --data-binary '{"input":"Chrome updates failing on endpoints 1-3. Investigate and propose remediation.","endpoint_ids":[1,2,3],"mode":"propose"}'

returns `run_id`

Terminal 2: fetch the run results (replace RUN_ID)

curl http://localhost:4000/api/runs/RUN_ID | jq . 

## How it works
1) POST /api/runs
   - A new AgentRun row is created with status queued and endpoint_ids saved into state.
   - An Oban job is enqueued with the run_id.

2) Background job executes the run
   - Step 1 (plan): planner prompt is sent to the LLM with allowlisted tools and strict JSON rules. The plan is validated and stored as a plan step.
   - Step 2 (tool_call): each plan step becomes a tool_call step and is executed against seeded data.
   - Step 3 (observation): the tool result is stored as an observation step. This observation is what the proposer later uses to draft the remediation proposal.
   - Step 4 (proposal): proposer prompt is sent with observations and allowlisted templates. The proposal is validated and stored as a proposal step.
   - Step 5 (final): a final step is stored and the run status is marked succeeded.
   - On any failure, an error step is stored and the run is marked failed (fail‑closed).

3) GET /api/runs/:id
   - Returns the run and its steps ordered by inserted_at for full auditability.
   - The remediation proposal is found in the step with step_type "proposal" under output.remediation.

## Architecture
AgentOps is a Phoenix app with a small domain model and a background runner that drives each remediation run. The core pieces are intentionally narrow to keep the workflow deterministic and auditable.

Core flow:
- `AgentOpsWeb.RunsController` accepts requests and creates `AgentRun` records.
- An Oban job (`AgentOps.Agent.RunnerJob`) processes the run asynchronously.
- The runner (`AgentOps.Agent.Runner`) orchestrates the plan → tool calls → observations → proposal → final steps, persisting each step as an `AgentStep`.

LLM boundary and validation:
- `AgentOps.Agent.Prompts` builds the planner/proposer prompts and declares the required JSON schemas.
- `AgentOps.LLM.Client` dispatches to the configured provider; `AgentOps.LLM.OpenAIClient` calls OpenAI’s Chat Completions API.
- `AgentOps.Agent.Validators` validates and (optionally) repairs LLM output to enforce schema and allowlists before anything is persisted or executed.

Tools and remediation templates:
- `AgentOps.Tools.Registry` is the allowlist and dispatch for inventory tools the planner may call.
- `AgentOps.Tools.Inventory` implements the read‑only inventory queries against seeded endpoint data.
- `AgentOps.Tools.Scripts` defines remediation templates, required params, and validation for proposals:
  - `enable_windows_service` with params `{ "service": "gupdate" | "wuauserv" }`
  - `restart_service` with params `{ "service": "gupdate" | "wuauserv" }`
  - `reinstall_application` with params `{ "app_name": "chrome" }`
  The proposer prompt is given only these templates; the selected `template_id` and params are validated and stored in the proposal step output.

Data model:
- `AgentOps.AgentRun`: one remediation run with input, mode, status, and state.
- `AgentOps.AgentStep`: timeline of plan/tool/observation/proposal/final/error steps.
- `AgentOps.Endpoint`: simulated endpoints with inventory fields (hostname, OS version, services, software, last_seen_at).

Observability:
- `AgentOps.Observability.Log` attaches run/step metadata to structured logs for troubleshooting.

The API is JSON-only (`/api/runs`, `/api/runs/:id`, `/healthz`) and returns full step timelines for auditability.

## Example prompts
These show the full prompt strings constructed for the planner and proposer (with sample inputs).

Planner prompt:
```
You are an expert sysadmin assistant. Return JSON only.

Input: Chrome updates failing on endpoints 1-3. Investigate and propose remediation.
Endpoint IDs: [1, 2, 3]

Return JSON with keys: hypothesis (string), steps (array of objects), stop_conditions (array of strings), risk_level ("low" | "medium" | "high").
Each step object must include tool (string) and input (object) fields.
If tool is get_service_status, input must include service_name (non-empty string).
service_name must be one of: gupdate, wuauserv.
All endpoint_ids in any step input must be a subset of the provided Endpoint IDs.

Allowed tools: get_installed_software, get_service_status
Use only these tools.
```

Validated planner JSON (example output):
```json
{
  "hypothesis": "gupdate service issues are blocking Chrome updates",
  "steps": [
    {"tool": "get_installed_software", "input": {"endpoint_ids": [1, 2, 3]}},
    {"tool": "get_service_status", "input": {"endpoint_ids": [1, 2, 3], "service_name": "gupdate"}}
  ],
  "stop_conditions": ["gupdate is running and up to date"],
  "risk_level": "low"
}
```

The observations from those tool calls are then passed into the proposer prompt.

Proposer prompt:
```
You are an expert sysadmin assistant. Return JSON only.

Input: Chrome updates failing on endpoints 1-3. Investigate and propose remediation.
Endpoint IDs: [1, 2, 3]
Observations: [{"tool":"get_installed_software","result":{"1":{"chrome":"123.0.0"},"2":{"chrome":"121.0.0"},"3":{"chrome":"123.0.0"}}},{"tool":"get_service_status","result":{"1":"stopped","2":"disabled","3":"running"}}]

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

Allowed templates: enable_windows_service, reinstall_application, restart_service
Use only these template_id values.
```

Validated proposer JSON (example output):
```json
{
  "summary": "Chrome updates are failing on endpoints 1 and 2 due to gupdate service issues, while endpoint 3 is healthy.",
  "findings": [
    "Endpoint 1 has the gupdate service stopped, preventing Chrome updates.",
    "Endpoint 2 has the gupdate service disabled, preventing Chrome updates.",
    "Endpoint 3 is running and has the latest version of Chrome."
  ],
  "remediation": {
    "template_id": "enable_windows_service",
    "params": {"service": "gupdate"},
    "confidence": 0.9
  }
}
```

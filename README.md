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

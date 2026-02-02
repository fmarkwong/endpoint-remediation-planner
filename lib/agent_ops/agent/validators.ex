defmodule AgentOps.Agent.Validators do
  @moduledoc false

  @risk_levels ["low", "medium", "high"]

  def validate_plan(raw, opts \\ []) when is_binary(raw) do
    with {:ok, plan} <- parse_with_repair(raw, opts),
         :ok <- validate_plan_shape(plan),
         :ok <- validate_plan_semantics(plan, opts) do
      {:ok, plan}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_proposal(raw, opts \\ []) when is_binary(raw) do
    with {:ok, proposal} <- parse_with_repair(raw, opts),
         :ok <- validate_proposal_shape(proposal),
         :ok <- validate_proposal_semantics(proposal, opts) do
      {:ok, proposal}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_with_repair(raw, opts) do
    case decode_json(raw) do
      {:ok, data} ->
        {:ok, data}

      {:error, :invalid_json} ->
        case Keyword.get(opts, :repair_fun) do
          nil ->
            {:error, :invalid_json}

          repair_fun ->
            repaired = repair_fun.("Return valid JSON only. Do not include any prose.")

            case decode_json(repaired) do
              {:ok, data} -> {:ok, data}
              {:error, _} -> {:error, :invalid_json}
            end
        end
    end
  end

  defp decode_json(raw) do
    case Jason.decode(raw) do
      {:ok, data} when is_map(data) -> {:ok, data}
      _ -> {:error, :invalid_json}
    end
  end

  defp validate_plan_shape(%{"hypothesis" => hypothesis, "steps" => steps, "stop_conditions" => stop, "risk_level" => risk})
       when is_binary(hypothesis) and is_list(steps) and is_list(stop) and is_binary(risk) do
    if Enum.all?(stop, &is_binary/1) and Enum.all?(steps, &valid_step_shape?/1) and risk in @risk_levels do
      :ok
    else
      {:error, :invalid_plan_shape}
    end
  end

  defp validate_plan_shape(_), do: {:error, :invalid_plan_shape}

  defp valid_step_shape?(%{"tool" => tool, "input" => input}) when is_binary(tool) and is_map(input),
    do: true

  defp valid_step_shape?(_), do: false

  defp validate_plan_semantics(plan, opts) do
    allowlist = Keyword.get(opts, :tool_allowlist, [])
    endpoint_ids = MapSet.new(Keyword.get(opts, :endpoint_ids, []))

    steps = Map.get(plan, "steps", [])

    cond do
      allowlist != [] and Enum.any?(steps, fn step -> Map.get(step, "tool") not in allowlist end) ->
        {:error, :unknown_tool}

      endpoint_ids != MapSet.new() and Enum.any?(steps, fn step ->
        case Map.get(step, "input") do
          %{"endpoint_ids" => ids} when is_list(ids) ->
            not Enum.all?(ids, &MapSet.member?(endpoint_ids, &1))

          %{endpoint_ids: ids} when is_list(ids) ->
            not Enum.all?(ids, &MapSet.member?(endpoint_ids, &1))

          _ ->
            false
        end
      end) ->
        {:error, :invalid_endpoint_ids}

      true ->
        :ok
    end
  end

  defp validate_proposal_shape(%{
         "summary" => summary,
         "findings" => findings,
         "remediation" => %{"template_id" => template_id, "params" => params, "confidence" => confidence}
       })
       when is_binary(summary) and is_list(findings) and is_binary(template_id) and is_map(params) and
              is_number(confidence) do
    if Enum.all?(findings, &is_binary/1) do
      :ok
    else
      {:error, :invalid_proposal_shape}
    end
  end

  defp validate_proposal_shape(_), do: {:error, :invalid_proposal_shape}

  defp validate_proposal_semantics(proposal, opts) do
    allowlist = Keyword.get(opts, :template_allowlist, [])
    params_validator = Keyword.get(opts, :params_validator)

    %{"remediation" => remediation} = proposal
    template_id = Map.get(remediation, "template_id")
    params = Map.get(remediation, "params")
    confidence = Map.get(remediation, "confidence")

    cond do
      allowlist != [] and template_id not in allowlist ->
        {:error, :unknown_template}

      not (confidence >= 0.0 and confidence <= 1.0) ->
        {:error, :invalid_confidence}

      is_function(params_validator, 2) ->
        case params_validator.(template_id, params) do
          :ok -> :ok
          {:error, reason} -> {:error, reason}
        end

      true ->
        :ok
    end
  end
end

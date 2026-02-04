defmodule AgentOps.LLM.Client do
  @moduledoc """
  Behaviour and dispatch layer for LLM providers.
  """

  @callback complete(String.t(), Keyword.t()) ::
              {:ok, %{content: String.t(), usage: map()}} | {:error, term()}

  @spec complete(String.t(), Keyword.t()) ::
          {:ok, %{content: String.t(), usage: map()}} | {:error, term()}
  def complete(prompt, opts) do
    provider = Application.get_env(:agent_ops, :llm_provider)

    if provider do
      provider.complete(prompt, opts)
    else
      {:error, :no_provider}
    end
  end
end

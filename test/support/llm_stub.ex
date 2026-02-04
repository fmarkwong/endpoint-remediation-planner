defmodule AgentOps.LLM.StubClient do
  @moduledoc """
  Minimal stub LLM client for tests that only need JSON shape validation.
  """

  @behaviour AgentOps.LLM.Client

  def complete(_prompt, _opts) do
    {:ok, %{content: "{\"ok\":true}", usage: %{prompt: 1, completion: 1}}}
  end
end

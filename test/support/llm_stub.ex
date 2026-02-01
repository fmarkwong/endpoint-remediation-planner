defmodule AgentOps.LLM.StubClient do
  @moduledoc false

  @behaviour AgentOps.LLM.Client

  def complete(_prompt, _opts) do
    {:ok, %{content: "{\"ok\":true}", usage: %{prompt: 1, completion: 1}}}
  end
end

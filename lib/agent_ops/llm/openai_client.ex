defmodule AgentOps.LLM.OpenAIClient do
  @moduledoc """
  OpenAI Chat Completions client with JSON-only responses.
  """

  @behaviour AgentOps.LLM.Client

  @spec complete(String.t(), Keyword.t()) ::
          {:ok, %{content: String.t(), usage: map()}} | {:error, term()}
  def complete(prompt, opts) when is_binary(prompt) and is_list(opts) do
    api_key = System.get_env("OPENAI_API_KEY")
    model = Keyword.get(opts, :model) || System.get_env("OPENAI_MODEL") || "gpt-4o-mini"

    if is_nil(api_key) or api_key == "" do
      {:error, :missing_api_key}
    else
      body = %{
        model: model,
        messages: [
          %{role: "system", content: "You are a helpful assistant."},
          %{role: "user", content: prompt}
        ],
        temperature: Keyword.get(opts, :temperature, 0.2),
        response_format: Keyword.get(opts, :response_format, %{type: "json_object"})
      }

      headers = [
        {"authorization", "Bearer #{api_key}"},
        {"content-type", "application/json"}
      ]

      request =
        Req.new(
          url: "https://api.openai.com/v1/chat/completions",
          headers: headers,
          json: body,
          receive_timeout: 30_000
        )

      case Req.post(request) do
        {:ok, %{status: 200, body: %{"choices" => [choice | _], "usage" => usage}}} ->
          content = get_in(choice, ["message", "content"]) || ""
          {:ok, %{content: content, usage: usage}}

        {:ok, %{status: 200, body: %{"choices" => [choice | _]}}} ->
          content = get_in(choice, ["message", "content"]) || ""
          {:ok, %{content: content, usage: %{}}}

        {:ok, %{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @spec complete(term(), term()) :: {:error, :invalid_prompt}
  def complete(_prompt, _opts), do: {:error, :invalid_prompt}
end

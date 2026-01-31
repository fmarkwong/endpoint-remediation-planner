defmodule PryHelpers do
  @default_keywords ["gondor", "phoenix"]

  @doc """
  ## Usage
      iex> PryHelpers.stack()
      # Prints only lines containing "gondor" or "phoenix"

      iex> PryHelpers.stack(false)
      # Prints full stacktrace

      iex> PryHelpers.stack(true, "batch")
      # Prints only lines containing "batch"

      iex> PryHelpers.stack(true, ["oban", "ecto"])
      # Prints only lines containing "oban" or "ecto"
  """
  def stack(filter? \\ true, keywords \\ @default_keywords) do
    Process.info(self(), :current_stacktrace)
    |> elem(1)
    |> maybe_filter(filter?, keywords)
    |> Enum.each(&IO.puts(Exception.format_stacktrace_entry(&1)))
  end

  def silence_logs do
    Logger.configure(level: :none)
  end

  defp maybe_filter(entries, true, keywords) when is_binary(keywords),
    do: maybe_filter(entries, true, [keywords])

  defp maybe_filter(entries, true, keywords) do
    Enum.filter(entries, fn entry ->
      formatted = Exception.format_stacktrace_entry(entry) |> String.downcase()
      Enum.any?(keywords, fn kw -> String.contains?(formatted, String.downcase(kw)) end)
    end)
  end

  defp maybe_filter(entries, false, _keywords), do: entries
end

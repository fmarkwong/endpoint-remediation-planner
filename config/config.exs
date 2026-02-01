# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :agent_ops,
  ecto_repos: [AgentOps.Repo],
  generators: [timestamp_type: :utc_datetime]

config :agent_ops, Oban,
  repo: AgentOps.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [agent_runs: 10]

config :agent_ops, :llm_provider, AgentOps.LLM.OpenAIClient

# Configures the endpoint
config :agent_ops, AgentOpsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: AgentOpsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AgentOps.PubSub,
  live_view: [signing_salt: "auYavPy9"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :agent_ops, AgentOps.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

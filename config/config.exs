# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :git_notes,
  ecto_repos: [GitNotes.Repo],
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET"),
  webhook_secret: System.get_env("GITHUB_WEBHOOK_SECRET"),
  http_adapter: HTTPoison,
  github_api_url: "https://api.github.com/app",
  github_api_version: "application/vnd.github.v3+json",
  github_app_id: "73363"


config :joken,
  default_signer: [
    signer_alg: "RS256",
    key_pem: System.get_env("PRIVATE_KEY")
  ]

# Configures the endpoint
config :git_notes, GitNotesWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "YPzoNJDvRInI3R3hCjVvRZ/7ps/q3bi03JEjeuIG24e/a66n7XmHeaIl24DaD5M8",
  render_errors: [view: GitNotesWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: GitNotes.PubSub,
  live_view: [signing_salt: "EVIQS8vy"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

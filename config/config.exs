# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :lucidboard,
  ecto_repos: [Lucidboard.Repo]

# Configures the endpoint
config :lucidboard, LucidboardWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base:
    "ynHoNC75BVRedbPP06+hVh6fj9+J2vP+K51G0J9F7xeeqYXSMpHJ4cYT1N70Qqlw",
  render_errors: [view: LucidboardWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Lucidboard.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "OcXvrFwwOpyqvo+oCIbpdeEdOKmvt3zs"
  ]

config :phoenix,
  template_engines: [leex: Phoenix.LiveView.Engine]

config :lucidboard, :templates, [
  %{
    name: "Retrospective",
    columns: ["What Went Well", "What Didn't Go Well", "Propouts"],
    settings: [likes_per_user: 5, likes_per_user_per_card: 3]
  },
  %{
    name: "Lean Coffee",
    columns: ["Ready", "Doing", "Done"],
    settings: [likes_per_user: 2, likes_per_user_per_card: 2]
  }
]

# Options are :dumb, :github, :pingfed. See documentation about authentication
config :lucidboard, :auth_provider, :dumb

config :lucidboard, :default_theme, "dark"

config :lucidboard, :themes, ~w(light dark)

config :lucidboard, :timezone, "America/Detroit"

config :phoenix, :json_library, Jason

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :oauth2, serializers: %{"application/json" => Jason}

config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, default_scope: "user:email"},
    pingfed: {Ueberauth.Strategy.PingFed, default_scope: "openid profile email"}
  ]

# config :ueberauth, Ueberauth.Strategy.Github.OAuth
#   site: "https://git.rockfin.com",
#   authorize_url: "https://git.rockfin.com/login/oauth/authorize",
#   token_url: "https://git.rockfin.com/login/oauth/access_token"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

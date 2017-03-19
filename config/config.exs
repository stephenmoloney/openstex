use Mix.Config

config :logger,
  backends: [:console],
  compile_time_purge_level: :error


config :openstex, AppClient,
  adapter: Openstex.Adapters.Bypass,
  bypass: [
    api_key: "bypass_key",
    username: "bypass_username",
    password: "bypass_password"
  ],
  keystone: [
    tenant_id: "bypass_tenant_id",
    endpoint: "http://localhost:3333/"
  ],
  swift: [
    account_temp_url_key1: :nil,
    account_temp_url_key2: :nil,
    region: "Bypass-Region-1"
  ],
  hackney: [
    timeout: 20000,
    recv_timeout: 180000
  ]


config :bypass,
  enable_debug_log: true


config :httpipe,
  adapter: HTTPipe.Adapters.Hackney

use Mix.Config

config :logger,
  backends: [:console],
  level: :debug,
  format: "\n$date $time [$level] $metadata$message"

import_config "#{Mix.env}.exs"

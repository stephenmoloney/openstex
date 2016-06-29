use Mix.Config

config :logger,
  backends: [:console],
  level: :debug,
  format: "\n$date $time [$level] $metadata$message"

if Mix.env == :prod do
  config :logger,
    backends: [:console],
    compile_time_purge_level: :warn
end

unless Mix.env == :test do
  import_config "#{Mix.env}.exs"
end

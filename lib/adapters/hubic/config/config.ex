defmodule Openstex.Adapters.Hubic.Config do
  @moduledoc :false
  alias Openstex.HttpQuery
  use Openstex.Adapter.Config


  # public

  def start_agent(openstex_client, opts) do
    Og.context(__ENV__, :debug)
    otp_app = Keyword.get(opts, :otp_app, :false) || Og.log_return(__ENV__, :error) |> raise()

    hubic_client = Module.concat(openstex_client, Hubic)
    Application.ensure_all_started(:ex_hubic)

    unless supervisor_exists?(hubic_client) do
      hubic_client.start_link()
      delay_until_client_started(openstex_client)
    end

    Agent.start_link(fn -> config({openstex_client, hubic_client}, otp_app) end, name: agent_name(openstex_client))
  end

  @doc "Gets the hubic related config variables from a supervised Agent"
  def hubic_config(openstex_client) do
    Agent.get(agent_name(openstex_client), fn(config) -> config[:hubic] end)
  end

  @doc :false
  def swift_service_name(), do: "swift"

  @doc :false
  def swift_service_type(), do: "object-store"


  # private

  defp config({openstex_client, hubic_client}, otp_app) do
    swift_config = swift_config(openstex_client, otp_app)
    keystone_config = keystone_config(openstex_client, otp_app)
    hubic_config = hubic_client.hubic_config()
    httpoison_config = httpoison_config(openstex_client, otp_app)

    [
     hubic: hubic_config,
     keystone: keystone_config,
     swift: swift_config,
     httpoison: httpoison_config
    ]
  end

  defp keystone_config(_openstex_client, _otp_app) do
    [
    tenant_id: :nil,
    user_id: :nil,
    endpoint: :nil
    ]
  end

  defp swift_config(_openstex_client, _otp_app) do
    [
    account_temp_url_key1: :nil,
    account_temp_url_key2: :nil,
    region: "hubic"
    ]
  end

  defp httpoison_config(openstex_client, otp_app) do

    httpoison_config = get_httpoison_config_from_env(openstex_client, otp_app)

    connect_timeout = httpoison_config[:connect_timeout] || 30000 # 30 seconds
    receive_timeout = httpoison_config[:receive_timeout] || (60000 * 30) # 30 minutes

    [
    timeout: connect_timeout,
    recv_timeout: receive_timeout,
    ]
  end

  defp supervisor_exists?(hubic_client) do
    Module.concat(ExHubic.Config, hubic_client) in Process.registered()
  end

  defp delay_until_client_started(openstex_client) do
    unless Module.concat(openstex_client, Hubic) in Process.registered() do
      :timer.sleep(200)
      delay_until_client_started(openstex_client)
    end
  end


end
defmodule Openstex.Adapters.Bypass.Config do
  @moduledoc :false
  @default_headers [{"Content-Type", "application/json; charset=utf-8"}] |> Enum.into(%{})
  @default_options [timeout: 10000, recv_timeout: 30000]
  @default_adapter HTTPipe.Adapters.Hackney
  use Openstex.Adapter.Config


  # public


  def start_agent(client, opts) do
    Og.klog("**Logging context**", __ENV__, :debug)
    otp_app = Keyword.get(opts, :otp_app, :false) || raise("Client has not been configured correctly, missing `:otp_app`")
    identity = create_identity(client, otp_app)
    Agent.start_link(fn -> config(client, otp_app, identity) end, name: agent_name(client))
  end


  @doc "Gets the bypass related config variables from a supervised Agent"
  def bypass_config(client) do
    Agent.get(agent_name(client), fn(config) -> config[:bypass] end)
  end


  @doc :false
  def swift_service_name(), do: "swift"


  @doc :false
  def swift_service_type(), do: "object-store"


  # private


  defp config(client, otp_app, identity) do
    [
     bypass: bypass_config(client, otp_app),
     keystone: keystone_config(client, otp_app, identity),
     swift: swift_config(client, otp_app, identity),
     hackney: hackney_config(client, otp_app)
    ]
  end


  defp bypass_config(client, otp_app) do
    __MODULE__.get_config_from_env(client, otp_app) |> Keyword.fetch!(:bypass)
  end


  defp keystone_config(client, otp_app, identity) do

    keystone_config = get_keystone_config_from_env(client, otp_app)

    tenant_id = keystone_config[:tenant_id] ||
                identity.token.tenant.id ||
                raise("cannot retrieve the tenant_id for keystone")

    user_id =   keystone_config[:user_id] ||
                identity.user.id ||
                raise("cannot retrieve the user_id for keystone")

    endpoint =  keystone_config[:endpoint] ||
                "http://localhost:3333/"

    [
    tenant_id: tenant_id,
    user_id: user_id,
    endpoint: endpoint
    ]
  end


  defp swift_config(client, otp_app, _identity) do


    swift_config = get_swift_config_from_env(client, otp_app)

    account_temp_url_key1 = swift_config[:account_temp_url_key1] ||
                            "bypass_temp_url_key1"

    account_temp_url_key2 = swift_config[:account_temp_url_key2] ||
                            "bypass_temp_url_key2"

    region = swift_config[:region] ||
             "Bypass-Region-1"

    [
    account_temp_url_key1: account_temp_url_key1,
    account_temp_url_key2: account_temp_url_key2,
    region: region
    ]
  end


  defp hackney_config(client, otp_app) do
    hackney_config = get_hackney_config_from_env(client, otp_app)
    connect_timeout = hackney_config[:timeout] || 30000
    recv_timeout = hackney_config[:recv_timeout] || (60000 * 30)
    [
    timeout: connect_timeout,
    recv_timeout: recv_timeout
    ]
  end


  defp create_identity(client, _otp_app) do
    Og.klog("**Logging context**", __ENV__, :debug)
    # return identity struct
    Openstex.Adapters.Bypass.Keystone.Utils.create_identity(client)
  end


end
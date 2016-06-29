defmodule Openstex.Adapters.Ovh.Cloudstorage.Config do
  @moduledoc :false
  @default_headers [{"Content-Type", "application/json; charset=utf-8"}]
  @default_options [timeout: 10000, recv_timeout: 30000]
  alias Openstex.HttpQuery
  alias Openstex.Services.Keystone.V2.Helpers.Identity
  alias Openstex.Adapters.Ovh.Cloudstorage.Keystone.Utils
  use Openstex.Adapter.Config


  # public


  def start_agent(openstex_client, opts) do
    Og.context(__ENV__, :debug)
    otp_app = Keyword.get(opts, :otp_app, :false) || Og.log_return(__ENV__, :error) |> raise()

    ovh_client = Module.concat(openstex_client, Ovh)
    Application.ensure_all_started(:ex_ovh)
    unless supervisor_exists?(ovh_client), do: ovh_client.start_link()
    identity = Utils.create_identity(openstex_client, otp_app)

    Agent.start_link(fn -> config({openstex_client, ovh_client}, otp_app, identity) end, name: agent_name(openstex_client))
  end


  @doc "Gets the rackspace related config variables from a supervised Agent"
  def ovh_config(openstex_client) do
    Agent.get(agent_name(openstex_client), fn(config) -> config[:ovh] end)
  end


  @doc :false
  def swift_service_name(), do: "swift"


  @doc :false
  def swift_service_type(), do: "object-store"


  # private


  defp config({openstex_client, ovh_client}, otp_app, identity) do
    swift_config = swift_config(openstex_client, otp_app)
    keystone_config = keystone_config(openstex_client, otp_app, identity)
    [
     ovh: ovh_client.ovh_config(),
     keystone: keystone_config,
     swift: swift_config,
     httpoison: httpoison_config(openstex_client, otp_app)
    ]
  end

  defp keystone_config(openstex_client, otp_app, identity) do

    keystone_config = get_keystone_config_from_env(openstex_client, otp_app)

    tenant_id = keystone_config[:tenant_id] ||
                identity.token.tenant.id ||
                Og.log_return("cannot retrieve the tenant_id for keystone", __ENV__, :error) |> raise()

    user_id =   keystone_config[:user_id] ||
                identity.user.id ||
                Og.log_return("cannot retrieve the user_id for keystone", __ENV__, :error) |> raise()

    endpoint =  keystone_config[:endpoint] ||
                "https://auth.cloud.ovh.net/v2.0"

    [
    tenant_id: tenant_id,
    user_id: user_id,
    endpoint: endpoint
    ]
  end

  defp swift_config(openstex_client, otp_app) do

    swift_config = get_swift_config_from_env(openstex_client, otp_app)

    account_temp_url_key1 = get_account_temp_url(openstex_client, otp_app, :key1) ||
                            swift_config[:account_temp_url_key1] ||
                            :nil

    if account_temp_url_key1 != :nil && swift_config[:account_temp_url_key1] != account_temp_url_key1 do
      Og.log("Warning, the `account_temp_url_key1` for the elixir `config.exs` for the swift client " <>
             "#{inspect openstex_client} does not match the `X-Account-Meta-Temp-Url-Key` on the server. " <>
             "This issue should probably be addressed. See Openstex.Adapter.Config.set_account_temp_url_key1/2.", __ENV__, :error)
    end

    account_temp_url_key2 = get_account_temp_url(openstex_client, otp_app, :key2) ||
                            swift_config[:account_temp_url_key2] ||
                            :nil

    if account_temp_url_key2 != :nil && swift_config[:account_temp_url_key2] != account_temp_url_key2 do
      Og.log("Warning, the `account_temp_url_key2` for the elixir `config.exs` for the swift client " <>
             "#{inspect openstex_client} does not match the `X-Account-Meta-Temp-Url-Key-2` on the server. " <>
             "This issue should probably be addressed. See Openstex.Adapter.Config.set_account_temp_url_key2/2.", __ENV__, :error)
    end

    region =   swift_config[:region] || "SBG1"

    [
    account_temp_url_key1: account_temp_url_key1,
    account_temp_url_key2: account_temp_url_key2,
    region: region
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


  defp get_account_temp_url(openstex_client, otp_app, key_atom) do

    ovh_client = Module.concat(openstex_client, Ovh)
    Application.ensure_all_started(:ex_ovh)
    unless supervisor_exists?(ovh_client), do: ovh_client.start_link()

    identity = Utils.create_identity(openstex_client, otp_app)
    x_auth_token = Map.get(identity, :token) |> Map.get(:id)
    endpoint = get_public_url(openstex_client, otp_app, identity)

    headers =
    @default_headers ++
    [
      {
        "X-Auth-Token", x_auth_token
      }
    ]

    header =
    case key_atom do
      :key1 -> "X-Account-Meta-Temp-Url-Key"
      :key2 -> "X-Account-Meta-Temp-Url-Key-2"
    end

    query =
    %HttpQuery{
              method: :get,
              uri: endpoint,
              body: "",
              headers: headers,
              options: @default_options,
              service: :openstack
              }
    {:ok, resp} = Openstex.Request.request(query, [], :nil)

    resp
    |> Map.get(:headers)
    |> Map.get(header)
  end

  defp get_public_url(openstex_client, otp_app, identity) do

    swift_config = get_swift_config_from_env(openstex_client, otp_app)

    region = swift_config[:region] || "SBG1"

    identity
    |> Map.get(:service_catalog)
    |> Enum.find(fn(%Identity.Service{} = service) -> service.name == swift_service_name() && service.type == swift_service_type() end)
    |> Map.get(:endpoints)
    |> Enum.find(fn(%Identity.Endpoint{} = endpoint) -> endpoint.region == region end)
    |> Map.get(:public_url)
  end

  defp supervisor_exists?(ovh_client) do
    Module.concat(ExOvh.Config, ovh_client) in Process.registered()
  end


end
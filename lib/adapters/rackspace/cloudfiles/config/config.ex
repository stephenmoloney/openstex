defmodule Openstex.Adapters.Rackspace.Cloudfiles.Config do
  @moduledoc :false
  @default_headers [{"Content-Type", "application/json; charset=utf-8"}]
  @default_options [timeout: 10000, recv_timeout: 30000]
  alias Openstex.HttpQuery
  alias Openstex.Services.Keystone.V2.Query
  alias Openstex.Services.Keystone.V2.Helpers.Identity
  alias Openstex.Services.Keystone.V2.Helpers, as: Keystone
  use Openstex.Adapter.Config


  # public


  def start_agent(client, opts) do
    Og.context(__ENV__, :debug)
    otp_app = Keyword.get(opts, :otp_app, :false) || raise("Client has not been configured correctly, missing `:otp_app`")
    identity = create_identity(client, otp_app)
    Agent.start_link(fn -> config(client, otp_app, identity) end, name: agent_name(client))
  end


  @doc "Gets the rackspace related config variables from a supervised Agent"
  def rackspace_config(client) do
    Agent.get(agent_name(client), fn(config) -> config[:rackspace] end)
  end


  @doc :false
  def swift_service_name(), do: "cloudFiles"


  @doc :false
  def swift_service_type(), do: "object-store"


  # private


  defp config(client, otp_app, identity) do
    [
     rackspace: rackspace_config(client, otp_app),
     keystone: keystone_config(client, otp_app, identity),
     swift: swift_config(client, otp_app, identity),
     httpoison: httpoison_config(client, otp_app)
    ]
  end


  defp rackspace_config(client, otp_app) do
    __MODULE__.get_config_from_env(client, otp_app) |> Keyword.fetch!(:rackspace)
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
                "https://identity.api.rackspacecloud.com/v2.0"

    [
    tenant_id: tenant_id,
    user_id: user_id,
    endpoint: endpoint
    ]
  end


  defp swift_config(client, otp_app, identity) do

    swift_config = get_swift_config_from_env(client, otp_app)

    account_temp_url_key1 = get_account_temp_url(client, otp_app, :key1) ||
                            swift_config[:account_temp_url_key1] ||
                            :nil

    if account_temp_url_key1 != :nil && swift_config[:account_temp_url_key1] != account_temp_url_key1 do
      Og.log("Warning, the `account_temp_url_key1` for the elixir `config.exs` for the swift client " <>
             "#{inspect client} does not match the `X-Account-Meta-Temp-Url-Key` on the server. " <>
             "This issue should probably be addressed. See Openstex.Adapter.Config.set_account_temp_url_key1/2.", __ENV__, :error)
    end

    account_temp_url_key2 = get_account_temp_url(client, otp_app, :key2) ||
                            swift_config[:account_temp_url_key2] ||
                            :nil

    if account_temp_url_key2 != :nil && swift_config[:account_temp_url_key2] != account_temp_url_key2 do
      Og.log("Warning, the `account_temp_url_key2` for the elixir `config.exs` for the swift client " <>
             "#{inspect client} does not match the `X-Account-Meta-Temp-Url-Key-2` on the server. " <>
             "This issue should probably be addressed. See Openstex.Adapter.Config.set_account_temp_url_key2/2.", __ENV__, :error)
    end

    region =   swift_config[:region] ||
               identity.user.mapail["RAX-AUTH:defaultRegion"] ||
               raise("cannot retrieve the region for keystone")

    if swift_config[:region] != :nil && identity.user.mapail["RAX-AUTH:defaultRegion"] != swift_config[:region] do
      Og.log("Warning, the `swift_config[:region]` for the elixir `config.exs` for the swift client " <>
             "#{inspect client} does not match the `RAX-AUTH:defaultRegion` on the server. " <>
             "This issue should probably be addressed.", __ENV__, :error)
    end

    [
    account_temp_url_key1: account_temp_url_key1,
    account_temp_url_key2: account_temp_url_key2,
    region: region
    ]
  end


  defp httpoison_config(client, otp_app) do

    httpoison_config = get_httpoison_config_from_env(client, otp_app)

    connect_timeout = httpoison_config[:connect_timeout] || 30000 # 30 seconds
    receive_timeout = httpoison_config[:receive_timeout] || (60000 * 30) # 30 minutes

    [
    timeout: connect_timeout,
    recv_timeout: receive_timeout,
    ]
  end


  defp get_account_temp_url(client, otp_app, key_atom) do

    identity = create_identity(client, otp_app)
    x_auth_token = Map.get(identity, :token) |> Map.get(:id)
    endpoint = get_public_url(client, otp_app, identity)

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


  defp create_identity(client, otp_app) do
    Og.context(__ENV__, :debug)

    rackpace_config = rackspace_config(client, otp_app)
    keystone_config = __MODULE__.get_config_from_env(client, otp_app) |> Keyword.fetch!(:keystone)

    api_key =  Keyword.get(rackpace_config, :api_key, :nil)
    password = Keyword.get(rackpace_config, :password, :nil)
    username = Keyword.fetch!(rackpace_config, :username)
    endpoint = Keyword.get(keystone_config, :endpoint, "https://identity.api.rackspacecloud.com/v2.0")

    {:ok, identity_resp} =
    case api_key do

      :nil ->
        {:ok, resp} = Query.get_token(endpoint, username, password) |> Openstex.Request.request([], :nil)

      api_key ->
        body =
        %{
          "auth" =>
                  %{
                    "RAX-KSKEY:apiKeyCredentials" => %{
                                                      "apiKey" => api_key,
                                                      "username" => username
                                                      }
                  }
        }
        |> Poison.encode!()
        query =
        %HttpQuery{
                  method: :post,
                  uri: endpoint <> "/tokens",
                  body: body,
                  headers: @default_headers,
                  options: @default_options,
                  service: :openstack
                  }
        {:ok, resp} = Openstex.Request.request(query, [], :nil)
    end
    Keystone.parse_nested_map_into_identity_struct(identity_resp.body)
  end


  defp get_public_url(client, otp_app, identity) do

    swift_config = get_swift_config_from_env(client, otp_app)

    region =   swift_config[:region] ||
               identity.user.mapail["RAX-AUTH:defaultRegion"] ||
               raise("cannot retrieve the region for keystone")

    identity
    |> Map.get(:service_catalog)
    |> Enum.find(fn(%Identity.Service{} = service) -> service.name == swift_service_name() && service.type == swift_service_type() end)
    |> Map.get(:endpoints)
    |> Enum.find(fn(%Identity.Endpoint{} = endpoint) ->  endpoint.region ==  region end)
    |> Map.get(:public_url)
  end


end
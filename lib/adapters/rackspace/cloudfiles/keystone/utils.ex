defmodule Openstex.Adapters.Rackspace.Cloudfiles.Keystone.Utils do
  @moduledoc :false
  alias Openstex.HttpQuery
  alias Openstex.Services.Keystone.V2.Helpers, as: Keystone
  alias Openstex.Services.Keystone.V2.Query
  @default_headers [{"Content-Type", "application/json; charset=utf-8"}]
  @default_options [timeout: 10000, recv_timeout: 30000]


  @doc :false
  @spec create_identity(atom) :: Identity.t | no_return
  def create_identity(openstex_client) do
    Og.context(__ENV__, :debug)

    rackpace_config = openstex_client.config().rackspace_config(openstex_client)
    keystone_config = openstex_client.config().keystone_config(openstex_client)

    api_key =  rackpace_config[:api_key]
    password = rackpace_config[:password]
    username = rackpace_config[:username]
    endpoint = keystone_config[:endpoint]

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


end


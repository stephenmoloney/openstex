defmodule Openstex.Adapters.Ovh.Webstorage.Keystone.Utils do
  @moduledoc :false
  alias Openstex.Services.Keystone.V2.Helpers, as: Keystone
  alias Openstex.Adapters.Ovh.Webstorage.Config
  @default_headers [{"Content-Type", "application/json; charset=utf-8"}]
  @default_options [timeout: 10000, recv_timeout: 30000]
  defstruct [ :domain, :storage_limit, :server, :endpoint, :username, :password, :tenant_name ]
  @type t :: %__MODULE__{
                        domain: String.t,
                        storage_limit: String.t,
                        server: String.t,
                        endpoint: String.t,
                        username: String.t,
                        password: String.t,
                        tenant_name: String.t
                        }

  @doc :false
  @spec webstorage(atom, String.t) :: __MODULE__.t | no_return
  def webstorage(ovh_client, cdn_name) do
    Og.context(__ENV__, :debug)

    properties = ExOvh.Services.V1.Webstorage.Query.get_service(cdn_name) |> ovh_client.request!() |> Map.fetch!(:body)
    credentials = ExOvh.Services.V1.Webstorage.Query.get_credentials(cdn_name) |> ovh_client.request!() |> Map.fetch!(:body)

    webstorage =
    %{
      "domain" => _domain,
      "storageLimit" => _storage_limit,
      "server" => _server,
      "endpoint" => _endpoint,
      "login" => username,
      "password" => _password,
      "tenant" => tenant_name
    } = Map.merge(properties, credentials)
    webstorage
    |> Map.delete("tenant") |> Map.delete("login")
    |> Map.put("username", username) |> Map.put("tenantName", tenant_name)
    |> Mapail.map_to_struct!(__MODULE__)
  end


  @doc :false
  @spec create_identity(atom, atom) :: Identity.t | no_return
  def create_identity(openstex_client, otp_app \\ :nil) do
    Og.context(__ENV__, :debug)

    ovh_client = Module.concat(openstex_client, Ovh)
    Application.ensure_all_started(:ex_ovh)
    unless supervisor_exists?(ovh_client), do: ovh_client.start_link()

    ovh_config = Config.get_config_from_env(openstex_client, otp_app) |> Keyword.get(:ovh, :nil) ||
                 openstex_client.config().ovh_config(openstex_client) ||
                 ovh_client.config() ||
                 Og.log_return("Cannot retrieve the ovh_config", __ENV__, :error) |> raise()

    cdn_name = ovh_config[:cdn_name] ||
               Og.log_return("Cannot retrieve the CDN name for the webstorage client #{openstex_client}", __ENV__, :error) |> raise()

    %{endpoint: endpoint, username: username, password: password, tenant_name: tenant_name} = webstorage(ovh_client, cdn_name)
    Keystone.authenticate!(endpoint, username, password, [tenant_name: tenant_name])
  end

  defp supervisor_exists?(ovh_client) do
    Module.concat(ExOvh.Config, ovh_client) in Process.registered()
  end

end
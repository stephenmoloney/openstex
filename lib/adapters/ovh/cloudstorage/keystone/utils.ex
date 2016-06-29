defmodule Openstex.Adapters.Ovh.Cloudstorage.Keystone.Utils do
  @moduledoc :false
  alias Openstex.Services.Keystone.V2.Helpers, as: Keystone
  alias Openstex.Adapters.Ovh.Cloudstorage.Config
  @default_headers [{"Content-Type", "application/json; charset=utf-8"}]
  @default_options [timeout: 10000, recv_timeout: 30000]


  @doc :false
  @spec create_identity(atom, atom) :: Identity.t | no_return
  def create_identity(openstex_client, otp_app \\ :nil) do
    Og.context(__ENV__, :debug)

    ovh_client = Module.concat(openstex_client, Ovh)
    Application.ensure_all_started(:ex_ovh)
    unless supervisor_exists?(ovh_client), do: ovh_client.start_link()

    keystone_config = Config.get_config_from_env(openstex_client, otp_app) |> Keyword.get(:keystone, :nil) ||
                      openstex_client.config().keystone_config(openstex_client)
    tenant_id = Keyword.fetch!(keystone_config, :tenant_id)
    ovh_user = ExOvh.Services.V1.Cloud.Query.get_users(tenant_id)
    |> ovh_client.request!()
    |> Map.get(:body)
    |> Enum.find(:nil,
      fn(user) -> %{"description" => "ex_ovh"} = user end
    )

    ovh_user_id =
    case ovh_user do
      :nil ->
        # create user for "ex_ovh" description
        ExOvh.Services.V1.Cloud.Query.create_user(tenant_id, "ex_ovh")
        |> ovh_client.request!()
        |> Map.get("id")
      ovh_user -> ovh_user["id"]
    end

    resp = ExOvh.Services.V1.Cloud.Query.regenerate_credentials(tenant_id, ovh_user_id)
    |> ovh_client.request!()
    password = resp.body["password"] || Og.log_return("Password not found", __ENV__, :error) |> raise()
    username = resp.body["username"] || Og.log_return("Username not found", __ENV__, :error) |> raise()
    endpoint = keystone_config[:endpoint] || "https://auth.cloud.ovh.net/v2.0"

    # make sure the regenerate credentials (in the external ovh api) had a chance to take effect
    :timer.sleep(1000)

    Keystone.authenticate!(endpoint, username, password, [tenant_id: tenant_id])
  end

  defp supervisor_exists?(ovh_client) do
    Module.concat(ExOvh.Config, ovh_client) in Process.registered()
  end

end


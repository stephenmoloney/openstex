defmodule Openstex.Adapters.Hubic.Keystone.Utils do
  @moduledoc :false
  alias Openstex.Services.Keystone.V2.Helpers.Identity

  # Note: This method constructs a 'fake' identity struct so that the Swift requests can be fulfilled without changing the Adapter radically.
  @doc :false
  @spec create_identity(atom) :: Identity.t | no_return
  def create_identity(openstex_client) do
    Og.context(__ENV__, :debug)

    hubic_client = Module.concat(openstex_client, Hubic)
    Application.ensure_all_started(:ex_hubic)
    unless supervisor_exists?(hubic_client), do: hubic_client.start_link()

    resp = ExHubic.Services.V1.Query.openstack_credentials() |> hubic_client.request!()

    public_url = resp.body["endpoint"] || Og.log_return("Could not get endpoint", __ENV__, :error) |> raise()
    xauth_token = resp.body["token"] || Og.log_return("Could not get xauth_token", __ENV__, :error) |> raise()
    xauth_token_expiry = resp.body["expires"] || Og.log_return("Could not get expiry time for xauth_token", __ENV__, :error) |> raise()

    %Identity{
              token: %Identity.Token{
                                     id: xauth_token,
                                     expires: xauth_token_expiry
              },
              service_catalog: [
                                %Identity.Service{
                                                  name: "swift",
                                                  type: "object-store",
                                                  endpoints: [
                                                              %Identity.Endpoint{
                                                                                region: "hubic",
                                                                                public_url: public_url
                                                              }
                                                  ]
                                }
              ],
              user: %Identity.User{},
              metadata: %Identity.Metadata{},
              trust: %Identity.Trust{}
    }
  end

  defp supervisor_exists?(client) do
    Process.whereis(client) != :nil
  end

end
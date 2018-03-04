defmodule Openstex.Adapters.Bypass.Keystone.Utils do
  @moduledoc :false
  alias Openstex.Keystone.V2.Helpers.Identity
  alias Openstex.Keystone.V2.Helpers.Identity.Token

  @doc :false
  def create_identity(_openstex_client) do
    # return identity struct

    token = %Token{
      audit_ids: ["audit_id_1", "audit_id_2"],
      expires: expiry(),
      id: "testing_id",
      issued_at: "2017-03-14T11:05:45.650933",
      tenant: %Token.Tenant{
        description: "Testing Project",
        enabled: true,
        id: "testing_auth_id",
        name: "Testing Project"
      }
    }

    service_catalog =
    [
    %Identity.Service{
      endpoints: [
        %Identity.Endpoint{
          admin_url: "http://compute.region1.localhost:3001/testing_auth_id",
          id: "testing_id",
          internal_url: "http://compute.region1.localhost:3001/testing_auth_id",
          public_url: "http://compute.region1.localhost:3001/testing_auth_id",
          region: "Bypass-Region-1"
        },
        %Identity.Endpoint{
          admin_url: "http://compute.region2.localhost:3001/testing_auth_id",
          id: "testing_id",
          internal_url: "http://compute.region2.localhost:3001/testing_auth_id",
          public_url: "http://compute.region2.localhost:3001/testing_auth_id",
          region: "Bypass-Region-2"
        }
      ],
      endpoints_links: [],
      name: "nova",
      type: "compute"
    },
    %Identity.Service{
      endpoints: [
        %Identity.Endpoint{
          admin_url: "http://network.compute.region1.localhost:3001/",
          id: "testing_id",
          internal_url: "http://network.compute.region1.localhost:3001/",
          public_url: "http://network.compute.region1.localhost:3001/",
          region: "Bypass-Region-1"
        },
        %Identity.Endpoint{
          admin_url: "http://network.compute.region2.localhost:3001/",
          id: "testing_id",
          internal_url: "http://network.compute.region2.localhost:3001/",
          public_url: "http://network.compute.region2.localhost:3001/",
          region: "Bypass-Region-2"
        }
      ],
      endpoints_links: [],
      name: "neutron",
      type: "network"
     },
     %Identity.Service{
        endpoints: [
          %Identity.Endpoint{
            admin_url: "http://volume.compute.region1.localhost:3001/testing_auth_id",
            id: "testing_id",
            internal_url: "http://volume.compute.region1.localhost:3001/testing_auth_id",
            public_url: "http://volume.compute.region1.localhost:3001/testing_auth_id",
            region: "Bypass-Region-1"
          }
        ],
        endpoints_links: [],
        name: "cinderv2",
        type: "volumev2"
     },
     %Identity.Service{
        endpoints: [
          %Identity.Endpoint{
            admin_url: "http://image.compute.region1.localhost:3001/",
            id: "testing_id",
            internal_url: "http://image.compute.region1.localhost:3001/",
            public_url: "http://image.compute.region1.localhost:3001/",
            region: "Bypass-Region-1"
          },
        ],
        endpoints_links: [],
        name: "glance",
        type: "image"
       },
     %Identity.Service{
        endpoints: [
          %Identity.Endpoint{
            admin_url: "http://volume.compute.region1.localhost:3001/v1/testing_auth_id",
            id: "testing_id",
            internal_url: "http://volume.compute.region1.localhost:3001/v1/testing_auth_id",
            public_url: "http://volume.compute.region1.localhost:3001/v1/testing_auth_id",
            region: "Bypass-Region-1"
          }
        ],
        endpoints_links: [],
        name: "cinder",
        type: "volume"
       },
     %Identity.Service{
        endpoints: [
          %Identity.Endpoint{
            admin_url: "http://storage.region1.localhost:3001",
            id: "testing_id",
            internal_url: "http://127.0.0.1:8888/v1/AUTH_testing_auth_id",
            public_url: "http://storage.region1.localhost:3001/v1/AUTH_testing_auth_id",
            region: "Bypass-Region-1"
            }
          ],
          endpoints_links: [],
          name: "swift",
          type: "object-store"
       },
     %Identity.Service{
      endpoints: [
        %Identity.Endpoint{
          admin_url: "http://auth.localhost:35357/v2.0",
          id: "testing_id",
          internal_url: "http://127.0.0.1:5000/v2.0",
          public_url: "http://auth.localhost:3001/",
          region: "Bypass-Region-1"
        }
      ],
       endpoints_links: [],
       name: "keystone",
       type: "identity"
     }
    ]

    user =
    %Identity.User{
      id: "testing_user_id",
      name: "testing_username",
      roles: [%{"name" => "_member_"}],
      roles_links: [],
      username: "testing_username"
    }

    metadata =
    %Identity.Metadata{
      is_admin: 0,
      metadata: nil,
      roles: ["role_id"]
    }

    trust = %Identity.Trust{
      id: nil,
      impersonation: nil,
      trust: nil,
      trustee_user_id: nil,
      trustor_user_id: nil
    }

    %{
      "token" => token,
      "service_catalog" => service_catalog,
      "user" => user,
      "metadata" => metadata,
      "trust" => trust
    }
    |> Identity.build()
  end

  # private

  defp expiry do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add((24 * 60 * 60))
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end
end

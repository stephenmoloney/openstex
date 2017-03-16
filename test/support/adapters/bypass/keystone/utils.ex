defmodule Openstex.Adapters.Bypass.Keystone.Utils do
  @moduledoc :false

  @doc :false
  def create_identity(_openstex_client) do
    # return identity struct

    token =
    %Openstex.Keystone.V2.Helpers.Identity.Token{
      audit_ids: ["audit_id_1", "audit_id_2"],
      expires: NaiveDateTime.utc_now() |> NaiveDateTime.add((24*60*60)) |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601(),
      id: "testing_id",
      issued_at: "2017-03-14T11:05:45.650933",
      tenant: %Openstex.Keystone.V2.Helpers.Identity.Token.Tenant{
        description: "Testing Project",
        enabled: true,
        id: "testing_auth_id",
        name: "Testing Project"
      }
    }

    service_catalog =
    [
    %Openstex.Keystone.V2.Helpers.Identity.Service{
      endpoints: [
        %Openstex.Keystone.V2.Helpers.Identity.Endpoint{
          admin_url: "http://compute.region1.localhost:3333/testing_auth_id",
          id: "testing_id",
          internal_url: "http://compute.region1.localhost:3333/testing_auth_id",
          public_url: "http://compute.region1.localhost:3333/testing_auth_id",
          region: "Bypass-Region-1"
        },
        %Openstex.Keystone.V2.Helpers.Identity.Endpoint{
          admin_url: "http://compute.region2.localhost:3333/testing_auth_id",
          id: "testing_id",
          internal_url: "http://compute.region2.localhost:3333/testing_auth_id",
          public_url: "http://compute.region2.localhost:3333/testing_auth_id",
          region: "Bypass-Region-2"
        }
      ],
      endpoints_links: [],
      name: "nova",
      type: "compute"
    },
    %Openstex.Keystone.V2.Helpers.Identity.Service{
      endpoints: [
        %Openstex.Keystone.V2.Helpers.Identity.Endpoint{
          admin_url: "http://network.compute.region1.localhost:3333/",
          id: "testing_id",
          internal_url: "http://network.compute.region1.localhost:3333/",
          public_url: "http://network.compute.region1.localhost:3333/",
          region: "Bypass-Region-1"
        },
        %Openstex.Keystone.V2.Helpers.Identity.Endpoint{
          admin_url: "http://network.compute.region2.localhost:3333/",
          id: "testing_id",
          internal_url: "http://network.compute.region2.localhost:3333/",
          public_url: "http://network.compute.region2.localhost:3333/",
          region: "Bypass-Region-2"
        }
      ],
      endpoints_links: [],
      name: "neutron",
      type: "network"
     },
     %Openstex.Keystone.V2.Helpers.Identity.Service{
        endpoints: [
          %Openstex.Keystone.V2.Helpers.Identity.Endpoint{
            admin_url: "http://volume.compute.region1.localhost:3333/testing_auth_id",
            id: "testing_id",
            internal_url: "http://volume.compute.region1.localhost:3333/testing_auth_id",
            public_url: "http://volume.compute.region1.localhost:3333/testing_auth_id",
            region: "Bypass-Region-1"
          }
        ],
        endpoints_links: [],
        name: "cinderv2",
        type: "volumev2"
     },
     %Openstex.Keystone.V2.Helpers.Identity.Service{
        endpoints: [
          %Openstex.Keystone.V2.Helpers.Identity.Endpoint{
            admin_url: "http://image.compute.region1.localhost:3333/",
            id: "testing_id",
            internal_url: "http://image.compute.region1.localhost:3333/",
            public_url: "http://image.compute.region1.localhost:3333/",
            region: "Bypass-Region-1"
          },
        ],
        endpoints_links: [],
        name: "glance",
        type: "image"
       },
     %Openstex.Keystone.V2.Helpers.Identity.Service{
        endpoints: [
          %Openstex.Keystone.V2.Helpers.Identity.Endpoint{
            admin_url: "http://volume.compute.region1.localhost:3333/v1/testing_auth_id",
            id: "testing_id",
            internal_url: "http://volume.compute.region1.localhost:3333/v1/testing_auth_id",
            public_url: "http://volume.compute.region1.localhost:3333/v1/testing_auth_id",
            region: "Bypass-Region-1"
          }
        ],
        endpoints_links: [],
        name: "cinder",
        type: "volume"
       },
     %Openstex.Keystone.V2.Helpers.Identity.Service{
        endpoints: [
          %Openstex.Keystone.V2.Helpers.Identity.Endpoint{
            admin_url: "http://storage.region1.localhost:3333",
            id: "testing_id",
            internal_url: "http://127.0.0.1:8888/v1/AUTH_testing_auth_id",
            public_url: "http://storage.region1.localhost:3333/v1/AUTH_testing_auth_id",
            region: "Bypass-Region-1"
            }
          ],
          endpoints_links: [],
          name: "swift",
          type: "object-store"
       },
     %Openstex.Keystone.V2.Helpers.Identity.Service{
      endpoints: [
        %Openstex.Keystone.V2.Helpers.Identity.Endpoint{
          admin_url: "http://auth.localhost:35357/v2.0",
          id: "testing_id",
          internal_url: "http://127.0.0.1:5000/v2.0",
          public_url: "http://auth.localhost:3333/",
          region: "Bypass-Region-1"
        }
      ],
       endpoints_links: [],
       name: "keystone",
       type: "identity"
     }
    ]

    user =
    %Openstex.Keystone.V2.Helpers.Identity.User{
      id: "testing_user_id",
      name: "testing_username",
      roles: [%{"name" => "_member_"}],
      roles_links: [],
      username: "testing_username"
    }

    metadata =
    %Openstex.Keystone.V2.Helpers.Identity.Metadata{
      is_admin: 0,
      metadata: nil,
      roles: ["role_id"]
    }

    trust = %Openstex.Keystone.V2.Helpers.Identity.Trust{
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
    |> Openstex.Keystone.V2.Helpers.Identity.build()
  end

end


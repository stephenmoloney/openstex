defmodule Openstex.Keystone.V2.Helpers do
  @moduledoc ~s"""
  A module that provides helper functions for executing more complex multi-step queries
  for Keystone authentication.

  See the `ExOvh` library for an example usage of the helpers module.
  """
  alias Openstex.Request
  alias Openstex.Keystone.V2.Helpers.Identity


  @doc ~s"""
  Helper function to authenticate openstack using keystone (identity) api. Returns a
  `Openstex.Helpers.V2.Keystone.Identity` struct.

  ## Arguments

  - ```endpoint```: the endpoint to which the http request should be sent for accessing keystone authentication.
  - ```username```: openstack username
  - ```password```: openstack password
  - ```tenant```: A Keyword list as follows: [tenant_id: tenant_id, tenant_name: tenant_name].
                  One or the other should be present or {:error, message} is returned.

  """
  @spec authenticate(String.t, String.t, String.t, Keyword.t) :: {:ok, Identity.t} | {:error, HTTPipe.Conn.t} | {:error, any}
  def authenticate(endpoint, username, password, tenant) do
    token_request = Openstex.Keystone.V2.get_token(endpoint, username, password)
    identity_request = fn(token, endpoint, tenant) -> Openstex.Keystone.V2.get_identity(token, endpoint, tenant) end

    with {:ok, conn} <- Request.request(token_request, :nil),
         token = conn.response.body |> Map.get("access") |> Map.get("token") |> Map.get("id"),
         {:ok, conn} <- Request.request(identity_request.(token, endpoint, tenant), :nil) do
      {:ok, parse_nested_map_into_identity_struct(conn.response.body)}
    end
    |> case do
      {:ok, identity} -> {:ok, identity}
      {:error, conn} -> {:error, conn}
    end
  end

  @doc ~s"""
  Helper function to authenticate openstack using keystone (identity) api. Returns a
  `Openstex.Helpers.V2.Keystone.Identity` struct.

  ## Arguments

  - ```endpoint```: the endpoint to which the http request should be sent for accessing keystone authentication.
  - ```token```: the x-auth token
  - ```tenant```: A Keyword list as follows: [tenant_id: tenant_id, tenant_name: tenant_name].
                  One or the other should be present or {:error, message} is returned.

  """
  @spec authenticate(String.t, String.t,  Keyword.t) :: {:ok, Identity.t} | {:error, HTTPipe.Conn.t} | {:error, any}
  def authenticate(endpoint, token, tenant) do
    identity_request = fn(token, endpoint, tenant) -> Openstex.Keystone.V2.get_identity(token, endpoint, tenant) end
    case Request.request(identity_request.(token, endpoint, tenant), :nil) do
      {:ok, conn} -> {:ok, parse_nested_map_into_identity_struct(conn.response.body)}
      {:error, conn} -> {:error, conn}
    end
    |> case do
      {:ok, identity} -> {:ok, identity}
      {:error, conn} -> {:error, conn}
    end
  end

  @doc ~s"""
  Defaults to authenticate(endpoint, token, []). See `authenticate/3`.
  """
  @spec authenticate(String.t, String.t, Keyword.t) :: {:ok, Identity.t} | {:error, Openstex.Response.t} | {:error, any}
  def authenticate(endpoint, token) do
    authenticate(endpoint, token, [])
  end
  @doc ~s"""
  Helper function to authenticate openstack using keystone (identity) api. Returns a
  `Openstex.Helpers.V2.Keystone.Identity` struct or raises and error. See `authenticate/3`.
  """
  @spec authenticate!(String.t, String.t) :: Identity.t | no_return
  def authenticate!(endpoint, token) do
    case authenticate(endpoint, token) do
      {:ok, identity} -> identity
      {:error, conn} -> raise(Openstex.ResponseError, conn: conn)
    end
  end



  @doc ~s"""
  Helper function to authenticate openstack using keystone (identity) api. Returns a
  `Openstex.Helpers.V2.Keystone.Identity` struct or raises and error. See `authenticate/4`.
  """
  @spec authenticate!(String.t, String.t, String.t, Keyword.t) :: Identity.t | no_return
  def authenticate!(endpoint, username, password, tenant) do
    case authenticate(endpoint, username, password, tenant) do
      {:ok, identity} -> identity
      {:error, conn} -> raise(Openstex.ResponseError, conn: conn)
    end
  end


  @doc :false
  def parse_nested_map_into_identity_struct(identity_map) do
    identity = Map.fetch!(identity_map, "access")
    tenant = Map.fetch!(identity, "token")
    |> Map.fetch!("tenant")
    |> Identity.Token.Tenant.build()
    token = Map.fetch!(identity, "token") |> Map.delete("tenant") |> Map.put("tenant", tenant) |> Identity.Token.build()
    user = Map.get(identity, "user", %{}) |> Identity.User.build()
    metadata = Map.get(identity, "metadata", %{}) |> Identity.Metadata.build()
    trust = Map.get(identity, "trust", %{}) |> Identity.Trust.build()

    service_catalog =
    Map.fetch!(identity, "serviceCatalog")
    |> Enum.map(
      fn(service) ->
        endpoints = Map.get(service, "endpoints", []) |> Enum.map(&Identity.Endpoint.build/1)
        service = Map.delete(service, "endpoints") |> Map.put("endpoints", endpoints)
        Identity.Service.build(service)
      end
    )

    %{
      "token" => token,
      "service_catalog" => service_catalog,
      "user" => user,
      "metadata" => metadata,
      "trust" => trust
    }
    |> Identity.build()
  end


  defmodule Identity.Token.Tenant do
    @moduledoc :false
    defstruct [:description, :enabled, :id, :name]
    def build(map) do
      opts = [rest: :merge, transformations: [:snake_case]]
      Mapail.map_to_struct!(map, __MODULE__, opts)
    end
  end
  defmodule Identity.Token do
    @moduledoc :false
    defstruct [:audit_ids, :issued_at, :expires, :id, tenant: %Identity.Token.Tenant{}]
    def build(map) do
      opts = [rest: :merge, transformations: [:snake_case]]
      Mapail.map_to_struct!(map, __MODULE__, opts)
    end
  end
  defmodule Identity.Service do
    @moduledoc :false
    defstruct [endpoints: [], endpoints_links: [], type: "", name: ""]
    def build(map) do
      opts = [rest: :merge, transformations: [:snake_case]]
      Mapail.map_to_struct!(map, __MODULE__, opts)
    end
  end
  defmodule Identity.Endpoint do
    @moduledoc :false
    defstruct [:admin_url, :region, :internal_url, :id, :public_url]
    def build(map) do
      opts = [rest: :merge, transformations: [:snake_case]]
      Mapail.map_to_struct!(map, __MODULE__, opts)
    end
  end
  defmodule Identity.User do
    @moduledoc :false
    defstruct [:username, :roles_links, :id, :roles, :name]
    def build(map) do
      opts = [rest: :merge, transformations: [:snake_case]]
      Mapail.map_to_struct!(map, __MODULE__, opts)
    end
  end
  defmodule Identity.Metadata do
    @moduledoc :false
    defstruct [:metadata, :is_admin, :roles]
    def build(map) do
      opts = [rest: :merge, transformations: [:snake_case]]
      Mapail.map_to_struct!(map, __MODULE__, opts)
    end
  end
  defmodule Identity.Trust do
    @moduledoc :false
    defstruct [:trust, :id, :trustee_user_id, :trustor_user_id, :impersonation]
    def build(map) do
      opts = [rest: :merge, transformations: [:snake_case]]
      Mapail.map_to_struct!(map, __MODULE__, opts)
    end
  end
  defmodule Identity do
    @moduledoc :false
    defstruct [
      token: %Identity.Token{},
      service_catalog: [],
      user: %Identity.User{},
      metadata: %Identity.Metadata{},
      trust: %Identity.Trust{}
    ]
    def build(map) do
      opts = [rest: :merge, transformations: [:snake_case]]
      Mapail.map_to_struct!(map, __MODULE__, opts)
    end
  end


end
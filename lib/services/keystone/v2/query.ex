defmodule Openstex.Services.Keystone.V2.Query do
  @moduledoc ~S"""
  Helper functions to assist in building queries for openstack compatible keystone apis (version 2.0).

  ## Example

      Openstex.Services.Keystone.V2.Query.get_token(endpoint, username, password) |> ExHubic.request!()
  """
  @default_headers [{"Content-Type", "application/json; charset=utf-8"}]
  @default_options [timeout: 10000, recv_timeout: 30000]
  alias Openstex.HttpQuery


  @doc ~s"""
  Generate and return a token.

  ## Api

      POST /v2.0/​{tokens}

  ## Example

      Openstex.Services.Keystone.V2.Query.get_token(endpoint, username, password) |> ExHubic.request!()
  """
  @spec get_token(String.t, String.t, String.t) :: HttpQuery.t
  def get_token(endpoint, username, password) do
    body =
    %{
      "auth" =>
              %{
                "passwordCredentials" => %{
                                          "username" => username,
                                          "password" => password
                                          }
              }
    }
    |> Poison.encode!()
    %HttpQuery{
              method: :post,
              uri: endpoint <> "/tokens",
              body: body,
              headers: @default_headers,
              options: @default_options,
              service: :openstack
              }
  end


  @doc ~s"""
  Get various details about the identity access including token information, services information (service catalogue),
  user information, trust information and metadata.

  ## Api

      POST /v2.0/​{tokens}

  ## Example

      Openstex.Services.Keystone.V2.Query.get_identity_info(token, endpoint, tenant) |> ExHubic.request!()
  """
  @spec get_identity(String.t, String.t, Keyword.t) :: HttpQuery.t | no_return
  def get_identity(token, endpoint, tenant) when tenant == [] do
    body =
        %{
          "auth" =>
                  %{
                    "token" => %{"id" => token}
                  }
        } |> Poison.encode!()

    %HttpQuery{
              method: :post,
              uri: endpoint <> "/tokens",
              body: body,
              headers: @default_headers,
              options: @default_options,
              service: :openstack
              }
  end
  def get_identity(token, endpoint, tenant) do
    tenant_id = Keyword.get(tenant, :tenant_id, :nil)
    tenant_name = Keyword.get(tenant, :tenant_name, :nil)
    body =
    case tenant_name do
      :nil ->
        %{
          "auth" =>
                  %{
                    "tenantId" => tenant_id,
                    "token" => %{"id" => token}
                  }
        } |> Poison.encode!()
      _ ->
        %{
          "auth" =>
                  %{
                    "tenantName" => tenant_name,
                    "token" => %{"id" => token}
                  }
        } |> Poison.encode!()
    end

    %HttpQuery{
              method: :post,
              uri: endpoint <> "/tokens",
              body: body,
              headers: @default_headers,
              options: @default_options,
              service: :openstack
              }
  end


end
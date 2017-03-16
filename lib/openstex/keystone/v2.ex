defmodule Openstex.Keystone.V2 do
  @moduledoc ~S"""
  Helper functions to assist in building queries for openstack compatible keystone apis (version 2.0).

  ## Example

      Openstex.Keystone.V2.get_token(endpoint, username, password) |> ExHubic.request!()
  """
  alias Openstex.Transformation.Body
  @default_headers %{"Content-Type" => "application/json; charset=utf-8"}
  @default_options [timeout: 10000, recv_timeout: 30000]


  @doc ~s"""
  Generate and return a token.

  ## Api

      POST /v2.0/​{tokens}

  ## Example

      Openstex.Keystone.V2.get_token(endpoint, username, password) |> ExHubic.request!()
  """
  @spec get_token(String.t, String.t, String.t) :: HTTPipe.Conn.t
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
    req = %HTTPipe.Request{
      method: :post,
      url: endpoint <> "/tokens",
      headers: @default_headers
    }
    Map.put(HTTPipe.Conn.new(), :request, req)
    |> Body.apply(body)
    |> HTTPipe.Conn.put_adapter_options(@default_options)
  end


  @doc ~s"""
  Get various details about the identity access including token information, services information (service catalogue),
  user information, trust information and metadata.

  ## Api

      POST /v2.0/​{tokens}

  ## Example

      Openstex.Keystone.V2.get_identity(token, endpoint, [tenant_id: "tenant_id"]) |> ExHubic.request!()
  """
  @spec get_identity(String.t, String.t, Keyword.t) :: HTTPipe.Conn.t | no_return
  def get_identity(token, endpoint, tenant) when tenant == [] do
    body =
    %{
      "auth" =>
              %{
                "token" => %{"id" => token}
              }
    } |> Poison.encode!()
    req = %HTTPipe.Request{
      method: :post,
      url: endpoint <> "/tokens",
      headers: @default_headers
    }
    Map.put(HTTPipe.Conn.new(), :request, req)
    |> Body.apply(body)
    |> HTTPipe.Conn.put_adapter_options(@default_options)
  end
  def get_identity(token, endpoint, tenant) when is_list(tenant) do
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

    req = %HTTPipe.Request{
      method: :post,
      url: endpoint <> "/tokens",
      headers: @default_headers
    }
    Map.put(HTTPipe.Conn.new(), :request, req)
    |> Body.apply(body)
    |> HTTPipe.Conn.put_adapter_options(@default_options)
  end


end
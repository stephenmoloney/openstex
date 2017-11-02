defmodule Openstex.Keystone.V2Test do
  use ExUnit.Case, async: false


  test "get_token(String.t, String.t, String.t)" do
    expected = %HTTPipe.Conn{
      adapter_options: [timeout: 10000, recv_timeout: 30000],
      request: %HTTPipe.Request{
        body: "{\"auth\":{\"passwordCredentials\":{\"username\":\"test_username\",\"password\":\"test_password\"}}}",
        headers: %{"Content-Type" => "application/json; charset=utf-8"},
        http_version: "1.1",
        method: :post,
        params: %{},
        url: "test_endpoint/tokens"
      },
    }
    |> Map.put(:completed_transformations, [:body])

    actual = Openstex.Keystone.V2.get_token("test_endpoint", "test_username", "test_password")
    assert expected.request == actual.request
    assert expected.adapter_options == actual.adapter_options
    assert Map.get(expected, :completed_transformations) == Map.get(actual, :completed_transformations)
  end


  test "get_identity(String.t, String.t, Keyword.t)" do
    expected = %HTTPipe.Conn{
      adapter_options: [timeout: 10000, recv_timeout: 30000],
      request: %HTTPipe.Request{
        body: "{\"auth\":{\"token\":{\"id\":\"test_token\"},\"tenantId\":\"test_tenant\"}}",
        headers: %{"Content-Type" => "application/json; charset=utf-8"},
        http_version: "1.1",
        method: :post,
        params: %{},
        url: "test_endpoint/tokens"
      }
    }
    |> Map.put(:completed_transformations, [:body])

    actual = Openstex.Keystone.V2.get_identity("test_token", "test_endpoint", [tenant_id: "test_tenant"])
    assert expected.request == actual.request
    assert expected.adapter_options == actual.adapter_options
    assert Map.get(expected, :completed_transformations) == Map.get(actual, :completed_transformations)
  end


end

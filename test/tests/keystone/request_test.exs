defmodule Openstex.Keystone.V2Test do
  use ExUnit.Case, async: false
  alias Openstex.Keystone.V2

  test "get_token(String.t, String.t, String.t)" do
    expected = %HTTPipe.Conn{
      adapter_options: [timeout: 10_000, recv_timeout: 30_000],
      request: %HTTPipe.Request{
        body: "{\"auth\":{\"passwordCredentials\":{\"password\":\"test_password\",\"username\":\"test_username\"}}}",
        headers: %{"Content-Type" => "application/json; charset=utf-8"},
        http_version: "1.1",
        method: :post,
        params: %{},
        url: "test_endpoint/tokens"
      },
    }
    |> Map.put(:completed_transformations, [:body])

    actual = V2.get_token("test_endpoint", "test_username", "test_password")
    assert expected.request == actual.request
    assert expected.adapter_options == actual.adapter_options
    assert Map.get(expected, :completed_transformations) == Map.get(actual, :completed_transformations)
  end

  test "get_identity(String.t, String.t, Keyword.t)" do
    expected = %HTTPipe.Conn{
      adapter_options: [timeout: 10_000, recv_timeout: 30_000],
      request: %HTTPipe.Request{
        body: "{\"auth\":{\"tenantId\":\"test_tenant\",\"token\":{\"id\":\"test_token\"}}}",
        headers: %{"Content-Type" => "application/json; charset=utf-8"},
        http_version: "1.1",
        method: :post,
        params: %{},
        url: "test_endpoint/tokens"
      }
    }
    |> Map.put(:completed_transformations, [:body])

    actual = V2.get_identity("test_token", "test_endpoint", [tenant_id: "test_tenant"])
    assert expected.request == actual.request
    assert expected.adapter_options == actual.adapter_options
    assert Map.get(expected, :completed_transformations) == Map.get(actual, :completed_transformations)
  end
end

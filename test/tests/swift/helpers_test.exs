defmodule Openstex.Swift.V1.HelpersTest do
  use ExUnit.Case, async: false


  test "client()" do
    expected = AppClient
    actual = AppClient.Swift.client()
    assert actual == expected
  end


  test "default_hackney_opts()" do
    expected = [timeout: 20000, recv_timeout: 180000]
    actual = AppClient.Swift.client() |> AppClient.Swift.client().config().hackney_config()
    assert expected == actual
  end


  test "get_public_url()" do
    expected = "http://storage.region1.localhost:3333/v1/AUTH_testing_auth_id"
    actual = AppClient.Swift.get_public_url()
    assert expected == actual
  end


  test "get_account()" do
    expected = "AUTH_testing_auth_id"
    actual = AppClient.Swift.get_account()
    assert expected == actual
  end


  test "get_account_tempurl_key() - 1" do
    bypass = Bypass.open(port: 3333)

    Bypass.expect(bypass, fn(conn) ->
      Plug.Conn.resp(conn, 204, "")
    end)

    expected = "bypass_temp_url_key1"
    actual = AppClient.Swift.get_account_tempurl_key()
    assert expected == actual

    Bypass.down(bypass)
  end


  test "get_account_tempurl_key() - 2" do
    bypass = Bypass.open(port: 3333)

    Bypass.expect(bypass, fn(conn) ->
      Plug.Conn.put_resp_header(conn, "x-account-meta-temp-url-key", "server_acquired_temp_url_key1")
      |> Plug.Conn.resp(204, "")
    end)

    expected = "server_acquired_temp_url_key1"
    actual = AppClient.Swift.get_account_tempurl_key()
    assert expected == actual

    Bypass.down(bypass)
  end


  test "get_account_tempurl_key() - 3" do
    bypass = Bypass.open(port: 3333)

    Bypass.expect(bypass, fn(conn) ->
      Plug.Conn.resp(conn, 204, "")
    end)

    expected = "bypass_temp_url_key2"
    actual = AppClient.Swift.get_account_tempurl_key(:key2)
    assert expected == actual

    Bypass.down(bypass)
  end


  test "get_account_tempurl_key() - 4" do
    bypass = Bypass.open(port: 3333)

    Bypass.expect(bypass, fn(conn) ->
      Plug.Conn.put_resp_header(conn, "x-account-meta-temp-url-key-2", "server_acquired_temp_url_key2")
      |> Plug.Conn.resp(204, "")
    end)

    expected = "server_acquired_temp_url_key2"
    actual = AppClient.Swift.get_account_tempurl_key(:key2)
    assert expected == actual

    Bypass.down(bypass)
  end


# Need to find a way to test in isolation from testing get_account_tempurl_key
#
#  test "set_account_temp_url_key(key_number, key)" do
#    bypass = Bypass.open(port: 3333)
#    expected = "temp_test_key"
#
#    Bypass.expect(bypass, fn(conn) ->
#      assert "POST" == conn.method
#      assert ({"x-account-meta-temp-url-key-2", expected} in conn.req_headers) == :true
#      Plug.Conn.resp(conn, 204, "")
#    end)
#
#    AppClient.Swift.set_account_temp_url_key(:key2, expected)
#    Bypass.down(bypass)
#  end


  test "upload_file(file, server_object, container, upload_opts \\ [])" do
    bypass = Bypass.open(port: 3333)

    Temp.track!()
    dir_path = Temp.mkdir!("swift_test")
    source_file = Path.join(dir_path, "swift_test_file")
    File.write(source_file, "swift test content")
    expected_etag = File.read!(source_file) |> :erlang.md5() |> Base.encode16(case: :lower)
    expected_url = "http://storage.region1.localhost:3333/v1/AUTH_testing_auth_id/test_container/test_object?format=json"

    Bypass.expect(bypass, fn(conn) ->
      assert "PUT" == conn.method
      assert ({"etag", expected_etag} in conn.req_headers) == :true
      Plug.Conn.put_resp_header(conn, "etag", expected_etag)
      |> Plug.Conn.resp(201, "")
    end)

    {:ok, conn} = AppClient.Swift.upload_file(source_file, "test_object", "test_container")
    assert {"etag", expected_etag} in conn.response.headers
    assert expected_url == conn.request.url

    Temp.cleanup()
    Bypass.down(bypass)
  end


  test "download_file(server_object, container)" do
    bypass = Bypass.open(port: 3333)
    expected_binary = "swift test!"
    expected_bytes = Integer.to_string(:erlang.byte_size(expected_binary))
    expected_etag = expected_binary |> :erlang.md5() |> Base.encode16(case: :lower)
    expected_url = "http://storage.region1.localhost:3333/v1/AUTH_testing_auth_id/test_container/test_object"

    Bypass.expect(bypass, fn(conn) ->
      assert "GET" == conn.method
      Plug.Conn.put_resp_header(conn, "etag", expected_etag)
      |> Plug.Conn.put_resp_header("content-length", expected_bytes)
      |> Plug.Conn.resp(200, expected_binary)
    end)

    {:ok, conn} = AppClient.Swift.download_file("test_object", "test_container")
    assert ({"etag", expected_etag} in conn.response.headers) == :true
    assert ({"content-length", expected_bytes} in conn.response.headers) == :true
    assert expected_url == conn.request.url

    Bypass.down(bypass)
  end


  test "delete_object(server_object, container)" do
    bypass = Bypass.open(port: 3333)

    Bypass.expect(bypass, fn(conn) ->
      assert "DELETE" == conn.method
      Plug.Conn.resp(conn, 204, "")
    end)

    {:ok, conn} = AppClient.Swift.delete_object("test_object", "test_container")
    expected_url = "http://storage.region1.localhost:3333/v1/AUTH_testing_auth_id/test_container/test_object"
    actual_url = conn.request.url
    assert expected_url == actual_url

    Bypass.down(bypass)
  end

  test "list_containers()" do
    bypass = Bypass.open(port: 3333)

    Bypass.expect(bypass, fn(conn) ->
      assert "GET" == conn.method
      body = [%{"bytes" => 0, "count" => 0, "name" => "test_container"}]
      |> Poison.encode!()
      Plug.Conn.resp(conn, 200, body)
    end)

    {:ok, actual_list} = AppClient.Swift.list_containers()
    expected_list = ["test_container"]
    assert expected_list == actual_list

    Bypass.down(bypass)
  end


  test "list_objects(pseudofolder, container, [nested: :true])" do
    bypass = Bypass.open(port: 3333)

    Bypass.expect(bypass, fn(conn) ->
      query = URI.decode_query(conn.query_string)
      body =
      cond do
        query == %{"delimiter" => "/", "format" => "json", "prefix" => ""} ->
          [
            %{"subdir" => "nested_folder/"},
            %{
              "name" => "test_object.txt"
            }
          ] |> Poison.encode!()
        query ==  %{"delimiter" => "/", "format" => "json", "prefix" => "nested_folder/"} ->
          [
            %{
              "name" => "nested_test_object.txt"
            }
          ] |> Poison.encode!()
        query == %{"format" => "json"} && (:false == Enum.member?(Map.keys(query), "delimiter")) ->
          [%{"name" => "test_container"}]
          |> Poison.encode!()
        :true -> [] |> Poison.encode!()
      end
      assert "GET" == conn.method
      Plug.Conn.resp(conn, 200, body)
    end)

    {:ok, actual_list} = AppClient.Swift.list_objects("", "test_container", [nested: :true])
    expected_list = ["nested_test_object.txt", "test_object.txt"]
    assert expected_list == actual_list

    Bypass.down(bypass)
  end


  test "list_objects(pseudofolder, container, [nested: :false])" do
    bypass = Bypass.open(port: 3333)

    Bypass.expect(bypass, fn(conn) ->
      query = URI.decode_query(conn.query_string)
      body =
      cond do
        query == %{"delimiter" => "/", "format" => "json", "prefix" => ""} ->
          [
            %{"subdir" => "nested_folder/"},
            %{
              "name" => "test_object.txt"
            }
          ] |> Poison.encode!()
        query ==  %{"delimiter" => "/", "format" => "json", "prefix" => "nested_folder/"} ->
          [
            %{
              "name" => "nested_test_object.txt"
            }
          ] |> Poison.encode!()
        query == %{"format" => "json"} && (:false == Enum.member?(Map.keys(query), "delimiter")) ->
          [%{"name" => "test_container"}]
          |> Poison.encode!()
        :true -> [] |> Poison.encode!()
      end
      assert "GET" == conn.method

      Plug.Conn.resp(conn, 200, body)
    end)

    {:ok, actual_list} = AppClient.Swift.list_objects("", "test_container", [nested: :false])
    expected_list = ["test_object.txt"]
    assert expected_list == actual_list

    Bypass.down(bypass)
  end


  test "list_pseudofolders(pseudofolder, container, opts)" do
    bypass = Bypass.open(port: 3333)

    Bypass.expect(bypass, fn(conn) ->
      body =
      [
        %{"subdir" => "nested_folder/"},
        %{
          "name" => "test_object.txt"
        }
      ] |> Poison.encode!()
      assert "GET" == conn.method
      Plug.Conn.resp(conn, 200, body)
    end)

    {:ok, actual_list} = AppClient.Swift.list_pseudofolders("", "test_container", [nested: :false])
    expected_list = ["nested_folder/"]
    assert expected_list == actual_list

    Bypass.down(bypass)
  end


  test "pseudofolder_exists?(pseudofolder, container)" do
    bypass = Bypass.open(port: 3333)

    Bypass.expect(bypass, fn(conn) ->
      body =
      [
        %{"subdir" => "nested_folder/"},
        %{
          "name" => "test_object.txt"
        }
      ] |> Poison.encode!()
      assert "GET" == conn.method
      Plug.Conn.resp(conn, 200, body)
    end)

    actual = AppClient.Swift.pseudofolder_exists?("nested_folder", "test_container")
    expected = :true
    assert expected == actual

    actual = AppClient.Swift.pseudofolder_exists?("nested_folder/", "test_container")
    expected = :true
    assert expected == actual

    Bypass.down(bypass)
  end


#  test "delete_pseudofolder(pseudofolder, container)" do
#    bypass = Bypass.open(port: 3333)
#
#    Bypass.expect(bypass, fn(conn) ->
#      if URI.decode_query(conn.query_string) == %{} do
#        assert "DELETE" == conn.method
#        Plug.Conn.resp(conn, 204, "")
#      else
#        assert "GET" == conn.method
#        query = URI.decode_query(conn.query_string)
#        body =
#        cond do
#          query == %{"delimiter" => "/", "format" => "json", "prefix" => ""} ->
#            [
#              %{"subdir" => "nested_folder/"},
#              %{
#                "name" => "test_object.txt"
#              }
#            ] |> Poison.encode!()
#          query ==  %{"delimiter" => "/", "format" => "json", "prefix" => "nested_folder/"} ->
#            [
#              %{
#                "name" => "nested_test_object.txt"
#              }
#            ] |> Poison.encode!()
#          query == %{"format" => "json"} && (:false == Enum.member?(Map.keys(query), "delimiter")) ->
#            [%{"name" => "test_container"}]
#            |> Poison.encode!()
#          :true -> [] |> Poison.encode!()
#        end
#        Plug.Conn.resp(conn, 200, body)
#      end
#    end)
#
#    Bypass.down(bypass)
#
#    AppClient.Swift.delete_pseudofolder("nested_folder", "test_container")
#    expected = :false
#
#    bypass = Bypass.open(port: 3334)
#
#    Bypass.expect(bypass, fn(conn) ->
#      if URI.decode_query(conn.query_string) == %{} do
#        assert "DELETE" == conn.method
#        Plug.Conn.resp(conn, 204, "")
#      else
#        assert "GET" == conn.method
#        body =
#        case URI.decode_query(conn.query_string) do
#          %{"delimiter" => "/", "format" => "json", "prefix" => ""} ->
#            [
#              %{
#                "name" => "test_object.txt"
#              }
#            ] |> Poison.encode!()
#          %{"delimiter" => "/", "format" => "json", "prefix" => "nested_folder/"} ->
#            [] |> Poison.encode!()
#          _ -> []
#        end
#        Plug.Conn.resp(conn, 200, body)
#      end
#    end)
#
#    actual = AppClient.Swift.pseudofolder_exists?("nested_folder", "test_container")
#    assert expected == actual
#
#
#    Bypass.down(bypass)
#  end


#  test "generate_temp_url(container, server_object, opts \\ [])" do
#    bypass = Bypass.open(port: 3333)
#    expected_host = "storage.region1.localhost"
#    expected_path = "/v1/AUTH_testing_auth_id/test_container/test_object.json"
#
#    Bypass.expect(bypass, fn(conn) ->
#      Plug.Conn.put_resp_header(conn, "x-account-meta-temp-url-key", "server_acquired_temp_url_key1")
#      |> Plug.Conn.resp(204, "")
#    end)
#
#    # Testing default opts
#    actual_temp_url = AppClient.Swift.generate_temp_url("test_container", "test_object.json")
#    now = DateTime.to_unix(DateTime.utc_now())
#    expected_time_range = Range.new((now + (5 * 60) - 2), (now + (5 * 60) + 2))
#    parsed_url = URI.parse(actual_temp_url)
#    qs_map = URI.decode_query(parsed_url.query)
#
#    assert parsed_url.host == expected_host
#    assert parsed_url.path == expected_path
#    actual_expiry = Map.get(qs_map, "temp_url_expires") |> String.to_integer()
#    assert (actual_expiry in expected_time_range)
#
#
#    Bypass.expect(bypass, fn(conn) ->
#      Plug.Conn.put_resp_header(conn, "x-account-meta-temp-url-key", "server_acquired_temp_url_key1")
#      |> Plug.Conn.resp(204, "")
#    end)
#
#    # Testing temp_url_expires_after opt
#    expected_expiry_time =  DateTime.to_unix(DateTime.utc_now()) + 3600
#    opts = [temp_url_expires_after: 3600]
#    expected_time_range = Range.new((expected_expiry_time - 2), (expected_expiry_time + 2))
#    actual_temp_url = AppClient.Swift.generate_temp_url("test_container", "test_object.json", opts)
#    parsed_url = URI.parse(actual_temp_url)
#    qs_map = URI.decode_query(parsed_url.query)
#
#    assert parsed_url.host == expected_host
#    assert parsed_url.path == expected_path
#    actual_expiry = Map.get(qs_map, "temp_url_expires") |> String.to_integer()
#    assert (actual_expiry in expected_time_range)
#
#    Bypass.expect(bypass, fn(conn) ->
#      Plug.Conn.put_resp_header(conn, "x-account-meta-temp-url-key", "server_acquired_temp_url_key1")
#      |> Plug.Conn.resp(204, "")
#    end)
#
#    # Testing temp_url_inline opt
#    opts = [temp_url_inline: :true]
#    actual_temp_url = AppClient.Swift.generate_temp_url("test_container", "test_object.json", opts)
#    parsed_url = URI.parse(actual_temp_url)
#    qs_map = URI.decode_query(parsed_url.query)
#
#    assert parsed_url.host == expected_host
#    assert parsed_url.path == expected_path
#    assert :true == Map.has_key?(qs_map, "inline")
#
#    Bypass.down(bypass)
#  end


end

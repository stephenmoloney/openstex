defmodule Openstex.Swift.V1Test do
  use ExUnit.Case, async: false


  test "account_info(String.t)" do
    expected = %HTTPipe.Conn{
      request: %HTTPipe.Request{
        body: nil,
        headers: %{},
        http_version: "1.1",
        method: :get,
        params: %{},
        url: "test_account?format=json"
      }
    }
    actual = Openstex.Swift.V1.account_info("test_account")
    assert expected.request == actual.request
  end


  test "create_container(String.t, String.t, Keyword.t)" do
    expected = %HTTPipe.Conn{
      request: %HTTPipe.Request{
        body: :nil,
        headers: %{"X-Container-Read" => ".r:*", "X-Container-Write" => "test_account"},
        http_version: "1.1",
        method: :put,
        params: %{},
        url: "test_account/test_container?format=json"
      }
    }

    actual = Openstex.Swift.V1.create_container("test_container", "test_account", [read_acl: ".r:*", write_acl: "test_account"])
    assert expected.request == actual.request

    expected = %HTTPipe.Conn{
      request: %HTTPipe.Request{
        body: :nil,
        headers: %{
          "X-Container-Read" => ".r:*",
          "X-Container-Write" => "test_account",
          "X-Container-Meta-Access-Control-Allow-Origin" => "http://localhost:4000",
          "X-Container-Meta-Access-Control-Max-Age" => "1000"
        },
        http_version: "1.1",
        method: :put,
        params: %{},
        url: "test_account/test_container?format=json"
      }
    }

    opts = [
      read_acl: ".r:*",
      write_acl: "test_account",
      headers: [
        {"X-Container-Meta-Access-Control-Allow-Origin", "http://localhost:4000"},
        {"X-Container-Meta-Access-Control-Max-Age", "1000"}
      ]
    ]
    actual = Openstex.Swift.V1.create_container("test_container", "test_account", opts)
    assert expected.request == actual.request

    opts = [
      headers: [
        {"X-Container-Read", ".r:*"},
        {"X-Container-Write", "test_account"},
        {"X-Container-Meta-Access-Control-Allow-Origin", "http://localhost:4000"},
        {"X-Container-Meta-Access-Control-Max-Age", "1000"}
      ]
    ]
    actual = Openstex.Swift.V1.create_container("test_container", "test_account", opts)
    assert expected.request == actual.request
  end


  test "modify_container(String.t, String.t, Keyword.t)" do
    expected = %HTTPipe.Conn{
      request: %HTTPipe.Request{
        body: :nil,
        headers: %{"X-Container-Read" => ".r:*", "X-Container-Write" => "test_account"},
        http_version: "1.1",
        method: :post,
        params: %{},
        url: "test_account/test_container?format=json"
      }
    }

    actual = Openstex.Swift.V1.modify_container("test_container", "test_account", [read_acl: ".r:*", write_acl: "test_account"])
    assert expected.request == actual.request

    expected = %HTTPipe.Conn{
      request: %HTTPipe.Request{
        body: :nil,
        headers: %{
          "X-Container-Read" => ".r:*",
          "X-Container-Write" => "test_account",
          "X-Container-Meta-Access-Control-Allow-Origin" => "http://localhost:4000",
          "X-Container-Meta-Access-Control-Max-Age" => "1000"
        },
        http_version: "1.1",
        method: :post,
        params: %{},
        url: "test_account/test_container?format=json"
      }
    }

    opts = [
      read_acl: ".r:*",
      write_acl: "test_account",
      headers: [
        {"X-Container-Meta-Access-Control-Allow-Origin", "http://localhost:4000"},
        {"X-Container-Meta-Access-Control-Max-Age", "1000"}
      ]
    ]
    actual = Openstex.Swift.V1.modify_container("test_container", "test_account", opts)
    assert expected.request == actual.request

    opts = [
      headers: [
        {"X-Container-Read", ".r:*"},
        {"X-Container-Write", "test_account"},
        {"X-Container-Meta-Access-Control-Allow-Origin", "http://localhost:4000"},
        {"X-Container-Meta-Access-Control-Max-Age", "1000"}
      ]
    ]
    actual = Openstex.Swift.V1.modify_container("test_container", "test_account", opts)
    assert expected.request == actual.request
  end


  test "delete_container(String.t, String.t)" do
    expected = %HTTPipe.Conn{
      request: %HTTPipe.Request{
        body: :nil,
        headers: %{},
        http_version: "1.1",
        method: :delete,
        params: %{},
        url: "test_account/test_container?format=json"
      }
    }

    actual = Openstex.Swift.V1.delete_container("test_container", "test_account")
    assert expected.request == actual.request
  end


  test "get_objects(String.t, String.t)" do
    expected = %HTTPipe.Conn{
      request: %HTTPipe.Request{
        body: :nil,
        headers: %{},
        http_version: "1.1",
        method: :get,
        params: %{},
        url: "test_account/test_container?format=json"
      }
    }

    actual = Openstex.Swift.V1.get_objects("test_container", "test_account")
    assert expected.request == actual.request
  end


  test "get_object(String.t, String.t, String.t, Keyword.t)" do
    expected = %HTTPipe.Conn{
      request: %HTTPipe.Request{
        body: :nil,
        headers: %{},
        http_version: "1.1",
        method: :get,
        params: %{},
        url: "test_account/test_container/path/to_object"
      }
    }

    actual = Openstex.Swift.V1.get_object("/path/to_object", "test_container", "test_account")
    assert expected.request == actual.request

    expected = HTTPipe.Conn.put_req_header(expected, "If-None-Match", "md5") # note httpipe will downcase headers!
    actual = Openstex.Swift.V1.get_object("/path/to_object", "test_container", "test_account", [headers: [{"if-none-match", "md5"}]])
    assert expected.request == actual.request
  end


  test "create_object(String.t, String.t, String.t, list)" do
    Temp.track!()
    dir_path = Temp.mkdir!("swift_test")
    source_file = Path.join(dir_path, "swift_test_file")
    File.write(source_file, "swift test content")
    body = File.read!(source_file)

    expected = %HTTPipe.Conn{
      request: %HTTPipe.Request{
        body: body,
        headers: %{"etag" => Base.encode16(:erlang.md5(body), case: :lower)},
        http_version: "1.1",
        method: :put,
        params: %{},
        url: "test_account/test_container/swift_test_file?format=json"
      }
    }

    actual = Openstex.Swift.V1.create_object("test_container", "test_account", source_file)
    assert expected.request == actual.request

    opts = [
      server_object: "destination_path",
      multipart_manifest: :true,
      x_object_manifest: "test_account/test_container/destination_path/",
      chunked_transfer: :true,
      content_type: "text/plain"
    ]
    expected = HTTPipe.Conn.put_req_url(expected, "test_account/test_container/destination_path?format=json&multipart-manifest=put")
    |> HTTPipe.Conn.put_req_header("X-Object-Manifest", "test_account/test_container/destination_path/")
    |> HTTPipe.Conn.put_req_header("Transfer-Encoding", "chunked")
    |> HTTPipe.Conn.put_req_header("Content-Type", "text/plain")
    actual = Openstex.Swift.V1.create_object("test_container", "test_account", source_file, opts)
    assert expected.request == actual.request


    opts = [
      x_detect_content_type: :true,
      e_tag: :false,
      content_disposition: "inline",
      delete_after: (24 * 60 * 60)
    ]
    expected = %HTTPipe.Conn{
      request: %HTTPipe.Request{
        body: body,
        headers: %{
          "x-detect-content-type" => "true",
          "content-disposition" => "inline",
          "x-delete-after" => 86400
        },
        http_version: "1.1",
        method: :put,
        params: %{},
        url: "test_account/test_container/swift_test_file?format=json"
      }
    }
    actual = Openstex.Swift.V1.create_object("test_container", "test_account", source_file, opts)
    assert expected.request == actual.request

    Temp.cleanup()
  end


  test "delete_object(String.t, String.t, String.t)" do
    expected = %HTTPipe.Conn{
      request: %HTTPipe.Request{
        body: :nil,
        headers: %{},
        http_version: "1.1",
        method: :delete,
        params: %{},
        url: "test_account/test_container/destination_path"
      }
    }

    actual = Openstex.Swift.V1.delete_object("destination_path", "test_container", "test_account")
    assert expected.request == actual.request
  end


  test "get_objects_in_folder(String.t, String.t, String.t)" do
    expected = %HTTPipe.Conn{
      request: %HTTPipe.Request{
        body: :nil,
        headers: %{},
        http_version: "1.1",
        method: :get,
        params: %{},
        url: "test_account/test_container?format=json&delimiter=%2F&prefix=test_folder%2F"
      }
    }

    actual = Openstex.Swift.V1.get_objects_in_folder("test_folder/", "test_container", "test_account")
    assert expected.request == actual.request
  end


end

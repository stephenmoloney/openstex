defmodule Openstex.Services.Swift.V1.Query do
  @moduledoc ~S"""
  Helper functions to assist in building queries for openstack compatible swift apis.

  Builds a query in a format that subsequently is easily modified. The query may ultimately be sent to
  an openstack/swift compliant api with a library such as HTTPotion or HTTPoison. See
  [ex_hubic](https://hex.pm/packages/ex_hubic) for an example implementation.

  ## Example

      client = ExHubic.Swift
      account = client.swift().get_account()
      Openstex.Services.Swift.V1.Query.account_info(account) |> ExHubic.request(query)
  """
  alias Openstex.Swift.Query


  # CONTAINER RELATED REQUESTS


  @doc ~S"""
  Get account details and containers for given account.

  ## Api

      GET /v1/​{account}​

  ## Example

  as implemented by the `ExHubic` library

      client = ExHubic.Swift
      account = client.swift().get_account()
      Openstex.Services.Swift.V1.Query.account_info(account) |> client.request()
  """
  @spec account_info(String.t) :: Openstack.t
  def account_info(account) do
    %Query{
           method: :get,
           uri: account,
           params: %{query_string: %{"format" => "json"}}
          }
  end


  @doc ~S"""
  Create a new container.

  ## Api

      PUT /v1/​{account}/{container}​


  ## Arguments

  - `container`: name of the container to be created
  - `account`: account of user accessing swift service
  - `opts`:

    - `read_acl`: headers for the container read access control list.
    - Examples:
        1. For giving public read access: `[read_acl: ".r:*" ]`, *note:* `.r:` can be any of `.ref:`, `.referer:`, or `.referrer:`.
        2. For giving a `*.some_website.com` read access: `[read_acl: ".r:.some_website.com"]`
        3. For giving a user accountread access, [read_acl: `user_account`]
        4. See [Swift Docs](https://github.com/openstack/swift/blob/master/swift/common/middleware/acl.py#L50) for more examples
        5. For giving write access and list access: `[read_acl: ".r:*,.rlistings"]`

    - `write_acl`: headers for the container write access control list. *Note:* For `X-Container-Write` referrers are not supported.
    - Examples:
      1. For giving write access to a user account: `[write_acl: "user_account"]`

    - `headers`: other metadata headers to be applied to the container.
    - Examples:
    1. Appying changes to the CORS restrictions for a container.
    eg:
    `[headers: [{"X-Container-Meta-Access-Control-Allow-Origin", "http://localhost:4000"}]]` # allowed origins to make cross-origin requests.
    `[headers: [{"X-Container-Meta-Access-Control-Max-Age", "1000"}]]` # validity of preflight requests in seconds.
    Other CORS headers include `X-Container-Meta-Access-Control-Allow-Headers`, `X-Container-Meta-Access-Control-Expose-Headers`

  ## Example

  as implemented by the `ExHubic` library

      client = ExHubic.Swift
      account = client.swift().get_account()
      Openstex.Services.Swift.V1.Query.create_container("new_container", account) |> client.request()
  """
  @spec create_container(String.t, String.t, Keyword.t) :: Openstack.t
  def create_container(container, account, opts \\ []) do
    read_acl = Keyword.get(opts, :read_acl, :nil)
    write_acl = Keyword.get(opts, :write_acl, :nil)
    headers = Keyword.get(opts, :headers, [])
    headers =
    cond do
      read_acl == :nil && write_acl == :nil -> []
      read_acl != :nil && write_acl == :nil -> [{"X-Container-Read", read_acl}]
      read_acl == :nil && write_acl != :nil -> [{"X-Container-Write", write_acl}]
      :true -> [{"X-Container-Read", read_acl}] ++ [{"X-Container-Write", write_acl}]
    end ++ headers
    %Query{
          method: :put,
          uri: account <> "/" <> container,
          headers: headers,
          params: %{query_string: %{"format" => "json"}}
          }
  end


  @doc ~S"""
  Modify a container. See docs for possible changes to [container metadata](http://developer.openstack.org/api-ref-objectstorage-v1.html)
  which are achieved by sending changes in the request headers.

  ## Api

      POST /v1/​{account}/{container}​

  ## Arguments

  - `container`: name of the container to be created
  - `account`: account of user accessing swift service
  - `opts`:

    - `read_acl`: headers for the container read access control list.
    - Examples:
        1. For giving public read access: `[read_acl: ".r:*" ]`
        2. For giving a `*.some_website.com` read access: `[read_acl: ".r:.some_website.com"]`
        3. For giving a user accountread access, [read_acl: `user_account`]
        4. See [Swift Docs](https://github.com/openstack/swift/blob/master/swift/common/middleware/acl.py#L50) for more examples
        5. For giving write access and list access: `[read_acl: ".r:*,.rlistings"]`

    - `write_acl`: headers for the container write access control list.
    - Example:
      1. For giving write access to a user account: `[write_acl: "user_account"]`

    - `headers`: other metadata headers to be applied to the container.
    - Examples:
    1. Appying changes to the CORS restrictions for a container.
    eg:
    `[headers: [{"X-Container-Meta-Access-Control-Allow-Origin", "http://localhost:4000"}]]` # allowed origins to make cross-origin requests.
    `[headers: [{"X-Container-Meta-Access-Control-Max-Age", "1000"}]]` # validity of preflight requests in seconds.
    Other CORS headers include `X-Container-Meta-Access-Control-Allow-Headers`, `X-Container-Meta-Access-Control-Expose-Headers`

  ## Example

  as implemented by the `ExHubic` library

      client = ExHubic.Swift
      account = client.swift().get_account()
      headers = []
      Openstex.Services.Swift.V1.Query.modify_container("new_container", account, headers) |> client.request()
  """
  @spec modify_container(String.t, String.t, Keyword.t) :: Openstack.t
  def modify_container(container, account, opts \\ []) do
    create_container(container, account, opts)
    |> Map.put(:method, :post)
  end

  @doc ~S"""
  Delete a container

  ## Api

      DELETE /v1/​{account}/{container}​

  ## Example

  as implemented by the `ExHubic` library

      client = ExHubic.Swift
      account = client.swift().get_account()
      Openstex.Services.Swift.V1.Query.delete_container("new_container", account) |> client.request(query)
  """
  @spec delete_container(String.t, String.t) :: Openstack.t
  def delete_container(container, account) do
    %Query{
           method: :delete,
           uri:  account <> "/" <> container,
           params: %{query_string: %{"format" => "json"}}
          }
  end


  @doc ~S"""
  Get information about the container

  ## Api

      DELETE /v1/​{account}/{container}​

  ## Example

  as implemented by the `ExHubic` library

      client = ExHubic.Swift
      account = client.swift().get_account()
      query = Openstex.Services.Swift.V1.Query.container_info("new_container", account) |> client.request()
  """
  @spec container_info(String.t, String.t) :: Openstack.t
  def container_info(container, account) do
    %Query{
          method: :head,
          uri: account <> "/" <> container,
          params: %{query_string: %{"format" => "json"}}
          }
    end


  # OBJECT RELATED REQUESTS


  @doc ~S"""
  List objects in a container

  ## Api

      GET /v1/​{account}​/{container}

  ## Example

  as implemented by the `ExHubic` library

      client = ExHubic.Swift
      account = client.swift().get_account()
      Openstex.Services.Swift.V1.Query.get_objects("new_container", account) |> client.request()
  """
  @spec get_objects(String.t, String.t) :: Openstack.t
  def get_objects(container, account) do
    %Query{
          method: :get,
          uri: account <> "/" <> container,
          params: %{query_string: %{"format" => "json"}}
          }
  end



  @doc ~S"""
  Get/Download a specific object (file)

  ## Api

      GET /v1/​{account}​/{container}/{object}

  ## Example

  as implemented by the `ExHubic` library

      client = ExHubic.Swift
      account = client.swift().get_account()
      server_object = "server_file.txt"
      container = "new_container"
      Openstex.Services.Swift.V1.Query.get_object(server_object, container, account) |> client.request(query)

  ## Arguments

  - `server_object`: The path name of the object in the server
  - `container`: The container of the object in the server
  - `account`: The account accessing the object
  - `opts`:
      - `headers`: Additional headers metadata in the request. Eg `[headers: [{"If-None-Match", "<local_file_md5>"}]`, this example would return `304` if the local file md5 was the same as the object etag on the server.
  """
  @spec get_object(String.t, String.t, String.t, Keyword.t) :: Openstack.t
  def get_object(server_object, container, account, opts \\ []) do
    headers = Keyword.get(opts, :headers, [])
    server_object = Openstex.Utils.remove_if_has_trailing_slash(server_object)
    %Query{
          method: :get,
          uri: account <> "/" <> container <> "/" <> server_object,
          headers: headers,
          params: %{}
          }
  end


  @doc """
  Create or replace an object (file).

  ## Api

      PUT /v1/​{account}​/{container}/{object}

  ## Example

  as implemented by the `ExHubic` library

      client = ExHubic.Swift
      account = client.swift().get_account()
      container = "new_container"
      object_name = "client_file.txt"
      client_object_pathname = Kernel.to_string(:code.priv_dir(:openstex)) <> "/" <> object_name
      Openstex.Services.Swift.V1.Query.create_object(container, account, client_object_pathname, [server_object: "server_file.txt"])
      |> client.request(query)

  ## Arguments

  - `container`: container to upload the file to
  - `account`: account uploading the file.
  - `client_object_pathname`: path of the file being uploaded.
  - `opts`:
    - `server_object`: filename under which the file will be stored on the openstack object storage server. defaults to the `client_object_pathname` if none given.
    - `multipart_manifest`: Defaults to `:false`. If `:true`, adds `multipart-manifest=put` to the query string. This option should be set to `:true` when uploading the manifest for a large static object.
    - `x_object_manifest`: Relevant to dynamic upload of large objects. Defaults to `:false`. If set, modifies the `X-Object-Manifest` header. The format used should be `[x_object_manifest: "container/myobject/"]`.
    - `chunked_transfer`: Defaults to `:false`, if `:true, set the `Transfer-Encoding` to `chunked`.
    - `content_type`: Defaults to `:false`,  otherwise changes the `Content-Type` header, which changes the MIME type for the object. Eg, `[content_type: "image/jpeg"]`
    - `x_detect_content_type`: Defaults to `:false`, otherwise changes the `X-Detect-Content-Type` header, the `X-Detect-Content-Type` header will be ignored and the actual file MIME type will be autodetected. Eg, `[x_detect_content_type: :true]`
    - `e_tag`: Defaults to `:true`, if `:true`, sets the `ETag` header of the file. Enhances upload integrity. If set to `:false`, the `ETag` header will be excluded.
    - `content_disposition`: Defaults to `:false`. Otherwise the `Content-Disposition` header can be changed from the default browser behaviour `inline` to another value. Eg `[content_disposition: "attachment; my_file.pdf"]`
    - `delete_after`: Defaults to `:false`. Otherwise the `X-Delete-After` header can be added so that the object is deleted after n seconds. Eg `[delete_after: (24 * 60 * 60)]` will delete the object in 1 day.
    - `e_tag`: Defaults to `:true`, if `:true`, sets the `ETag` header of the file. Enhances upload integrity. If set to `:false`, the `ETag` header will be excluded.

  ## Notes

  See the openstack docs for more information relating to [object uploads](http://docs.openstack.org/developer/swift/api/object_api_v1_overview.html) and
  [large object uploads](http://docs.openstack.org/developer/swift/overview_large_objects.html).
  For uploading large objects, the operation typically involves multiple queries so a [Helper function](https://github.com/stephenmoloney/openstex/lib/swift/v1/helpers.ex) is planned
  for large uploads.
  Large objects are categorized as those over 5GB in size.
  There are two ways of uploading large files - dynamic uploads and static uploads. See [here](http://docs.openstack.org/developer/swift/overview_large_objects.html#direct-api) for more information.
  """
  @spec create_object(String.t, String.t, String.t, list) :: Openstack.t
  def create_object(container, account, client_object_pathname, opts) do
    server_object = Keyword.get(opts, :server_object, Path.basename(client_object_pathname))

    # headers
    x_object_manifest = Keyword.get(opts, :x_object_manifest, :false)
    x_object_manifest = if x_object_manifest != :false, do: URI.encode(x_object_manifest), else: x_object_manifest
    chunked_transfer = Keyword.get(opts, :chunked_transfer, :false)
    content_type = Keyword.get(opts, :content_type, :false)
    x_detect_content_type = Keyword.get(opts, :x_detect_content_type, :false)
    content_disposition = Keyword.get(opts, :content_disposition, :false)
    delete_after = Keyword.get(opts, :delete_after, :false)
    e_tag = Keyword.get(opts, :e_tag, :true)

    # query_string
    multipart_manifest = Keyword.get(opts, :multipart_manifest, :false)


    case File.read(client_object_pathname) do
      {:ok, binary_object} ->
        path = account <> "/" <> container <> "/" <> server_object
        query_string =
        Map.merge(%{"format" => "json"},
          case multipart_manifest do
            :true -> %{"multipart-manifest" => "put"}
            :false -> %{}
          end
        )
        headers = if x_object_manifest != :false, do: [{"X-Object-Manifest", x_object_manifest}], else: []
        headers = if chunked_transfer != :false, do: headers ++ [{"Transfer-Encoding", "chunked"}], else: headers
        headers = if content_type != :false, do: headers ++ [{"Content-Type", content_type}], else: headers
        headers = if x_detect_content_type != :false, do: headers ++ [{"X-Detect-Content-Type", "true"}], else: headers
        headers = if e_tag != :false, do: headers ++ [{"ETag", Base.encode16(:erlang.md5(binary_object), case: :lower)}], else: headers
        headers = if content_disposition != :false, do: headers ++ [{"Content_Disposition", content_disposition}], else: headers
        headers = if delete_after != :false, do: headers ++ [{"X-Delete-After", delete_after}], else: headers
        %Query{

              method: :put,
              uri: path,
              headers: headers,
              params: %{
                        binary: binary_object,
                        query_string: query_string
                       }
              }
      {:error, posix_error} ->
        Og.context(__ENV__, :error)
        Og.log_return(posix_error, :error)
        posix_error
    end
  end


  @doc """
  Delete an Object (Delete a file)

  ## Api

      DELETE /v1/​{account}​/{container}/{object}

  ## Example

  as implemented by the `ExHubic` library

      client = ExHubic.Swift
      account = client.swift().get_account()
      container = "new_container"
      server_object = "server_file.txt"
      Openstex.Services.Swift.V1.Query.delete_object(server_object, container, account, server_object) |> client.request(query)
  """
  @spec delete_object(String.t, String.t, String.t) :: Openstack.t
  def delete_object(server_object, container, account) do
    server_object = Openstex.Utils.remove_if_has_trailing_slash(server_object)
    %Query{
          method: :delete,
          uri:  account <> "/" <> container <> "/" <> server_object,
          params: %{}
          }
  end


  # PSEUDOFOLDER RELATED REQUESTS


  @doc """
  List all objects and psuedofolders in a psuedofolder for a given container.

  ## Api

      GET /v1/​{account}​/{container}?prefix=pseudofolder&delimiter=/

  ## Notes

  - Query for only the top level objects and pseudofolders
  - Query execution will *not* return nested objects and pseudofolders
  - In order to view nested objects and pseudofolders, the function should be called recursively. See
  `Openstex.Helpers.list_pseudofolders_recursively/2` and `Openstex.Helpers.list_all_objects/3`.

  ## Example

  as implemented by the `ExHubic` library

      client = ExHubic.Swift
      account = client.swift().get_account()
      Openstex.Services.Swift.V1.Query.get_objects_in_folder("test_folder/", "default", account) |> client.request(query)
  """
  @spec get_objects_in_folder(String.t, String.t, String.t) :: list
  def get_objects_in_folder(pseudofolder \\ "", container, account) do
      q = get_objects(container, account)
      Map.put(q, :params, Map.merge(q.params, %{query_string: Map.merge(q.params.query_string, %{delimiter: "/", prefix: pseudofolder})}))
  end



end

defmodule Openstex.Swift.V1.Helpers do
  @moduledoc ~S"""
  Helper functions for executing more complex multi-step queries for Swift Object Storage.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias Openstex.Keystone.V2.Helpers.Identity
      alias Openstex.Swift.V1
      @behaviour Openstex.Swift.V1.Helpers

      @doc :false
      def client(), do: Keyword.fetch!(unquote(opts), :client)

      @doc :false
      def default_hackney_opts(), do: client() |> client().config().hackney_config()

      def get_public_url() do
        client()
        |> client().keystone().identity()
        |> Map.get(:service_catalog)
        |> Enum.find(fn(%Identity.Service{} = service) ->
          service.name == client().config().swift_service_name() &&
          service.type == client().config().swift_service_type()
        end)
        |> Map.get(:endpoints)
        |> Enum.find(fn(%Identity.Endpoint{} = endpoint) ->
          endpoint.region == client().config().swift_region(client())
        end)
        |> Map.get(:public_url)
      end

      def get_account() do
        public_url = get_public_url()
        path = URI.parse(public_url) |> Map.get(:path)
        {version, account} = String.split_at(path, 4)
        account
      end

      def get_endpoint() do
        public_url = get_public_url()
        path = URI.parse(public_url) |> Map.get(:path)
        {version, account} = String.split_at(path, 4)
        endpoint = String.split(public_url, account) |> List.first()
        endpoint
      end

      def get_account_tempurl_key(key_number \\ :key1) do

        header =
        case key_number do
          :key1 -> "X-Account-Meta-Temp-Url-Key"
          :key2 -> "X-Account-Meta-Temp-Url-Key-2"
        end

        # first attempt to get the account key from the swift server
        headers = V1.account_info(get_account())
        |> client().request!()
        |> Map.get(:response)
        |> Map.fetch!(:headers)
        key = Map.get(headers, header, :nil) || Map.get(headers, String.downcase(header), :nil)

        # then attempt to get the get_account() key from the config file
        cond do
          key == :nil && key_number == :key1 ->
            client().config().get_account_temp_url_key1(client())
          key == :nil && key_number == :key2 ->
            client().config().get_account_temp_url_key2(client())
          :true ->
            key
        end
#          if key != :nil, do: set_account_temp_url_key(key_number, key)
      end

      def set_account_temp_url_key(key_number \\ :key1, key \\ :nil) do
        {key, header} =
        case key_number do
          :key1 ->
            if key == :nil do
              {client().config().get_account_temp_url_key1(client()), "X-Account-Meta-Temp-Url-Key"}
            else
              {key, "X-Account-Meta-Temp-Url-Key"}
            end
          :key2 ->
            if key == :nil do
              {client().config().get_account_temp_url_key2(client()), "X-Account-Meta-Temp-Url-Key-2"}
            else
              {key, "X-Account-Meta-Temp-Url-Key-2"}
            end
        end
        put_temp_url_key(key, header, key_number)
      end

      def delete_container(container) do
        results =
        with {:ok, containers} <- client().swift().list_containers(),
          :true <- container in containers,
          {:ok, pseudofolders} <- client().swift().list_pseudofolders(container) do
          Enum.map(pseudofolders, fn(pseudofolder) ->
              client().swift().delete_pseudofolder(pseudofolder, container)
          end)
        else
          :false -> :ok
          {:error, %HTTPipe.Conn{} = conn} -> {:error, conn}
          other -> other
        end
        with :true <- Enum.all?(results, fn(res) -> res == :ok  end),
          {:ok, objs} <- client().swift().list_objects("", container),
          _res <- Enum.map(objs, &(client().swift().delete_object(&1, container))),
          {:ok, conn} = V1.delete_container(container, client().swift().get_account())
          |> client().request() do
            {:ok, conn}
        else
          :false -> {:error, results}
          {:error, %HTTPipe.Conn{} = conn} -> {:error, conn}
          other -> other
        end
      end

      def delete_object(server_object, container) do
        request = V1.delete_object(server_object, container, get_account())
        |> client().request()
      end

      def delete_object!(server_object, container) do
        case delete_object(server_object, container) do
          {:ok, conn} ->
            if conn.response.status_code == 204 and conn.response.body == "" do
              :ok
            else
              conn = V1.delete_object(server_object, container, get_account())
              raise(Openstex.ResponseError, conn: conn)
            end
          {:error, conn} ->
            conn = V1.delete_object(server_object, container, get_account())
            raise(Openstex.ResponseError, conn: conn)
        end
      end

      def upload_file(file, server_object, container, upload_opts \\ []) do
        upload_opts = upload_opts ++ [server_object: server_object]
        conn = V1.create_object(container, get_account(), file, upload_opts)
        client().request(conn)
      end

      def upload_file!(file, server_object, container, upload_opts \\ []) do
        case upload_file(file, server_object, container, upload_opts) do
          {:ok, conn} ->
            if conn.response.status_code in [200, 201] and conn.response.body == "" do
              :ok
            else
              upload_opts = upload_opts ++ [server_object: server_object]
              conn = V1.create_object(container, get_account(), file, upload_opts)
              raise(Openstex.ResponseError, conn: conn)
            end
          {:error, conn} ->
            upload_opts = upload_opts ++ [server_object: server_object]
            conn = V1.create_object(container, get_account(), file, upload_opts)
            raise(Openstex.ResponseError, conn: conn)
        end
      end

      def download_file(server_object, container) do
        conn = V1.get_object(server_object, container, get_account())
        client().request(conn)
      end

      def download_file!(server_object, container) do
        case download_file(server_object, container) do
          {:ok, conn} -> conn.response.body
          {:error, conn} ->
            conn = V1.get_object(server_object, container, get_account())
            raise(Openstex.ResponseError, conn: conn)
        end
      end

      def list_containers() do
        case Openstex.Swift.V1.account_info(get_account()) |> client().request() do
          {:ok, conn} ->
            list = Enum.map(conn.response.body, fn(container_infos) ->
              Map.fetch!(container_infos, "name")
            end)
            {:ok, list}
          {:error, conn} -> {:error, conn}
        end
      end

      def list_containers!() do
        case list_containers() do
          {:ok, containers} -> containers
          {:error, conn} -> raise(Openstex.ResponseError, conn: conn)
        end
      end

      def list_objects(container) do
        list_objects("", container, [nested: :true])
      end

      @spec list_objects!(String.t) :: list | no_return
      def list_objects!(container) do
        list_objects!("", container, [nested: :true])
      end


      def list_objects(pseudofolder, container, opts \\ [])
      def list_objects(pseudofolder, container, [nested: :true]) do
        with {:ok, list} <- list_containers(),
             :true <- Enum.member?(list, container),
             {:ok, pseudofolders} <- list_pseudofolders(pseudofolder, container, [nested: :true]),
             pseudofolders <- pseudofolders = [ pseudofolder  | pseudofolders ],
             objects = Enum.reduce(pseudofolders, [], fn(pseudofolder, acc) ->
               {:ok, objects} = get_objects_only_in_pseudofolder(pseudofolder, container, get_account())
               Enum.concat(objects, acc)
             end) do
           {:ok, objects}
        else
          :false -> {:error, "Unsuccessful request, container `#{container}` does not seem to exist."}
          {:error, conn} -> {:error, conn}
        end
      end
      def list_objects(pseudofolder, container, [nested: :false]) do
        case get_objects_only_in_pseudofolder(pseudofolder, container, get_account()) do
          {:ok, objects} -> {:ok, objects}
          {:error, conn} -> {:error, conn}
        end
      end
      def list_objects(pseudofolder, container, []) do
        list_objects(pseudofolder, container, [nested: :false])
      end

      def list_objects!(folder, container, opts \\ []) do
        case list_objects(folder, container, opts) do
          {:ok, objects} -> objects
          {:error, %HTTPipe.Conn{} = conn} -> raise(Openstex.ResponseError, conn: conn)
          {:error, msg} -> raise(msg)
        end
      end

      def list_pseudofolders(container) do
        list_pseudofolders("", container, [nested: :true])
      end

      def list_pseudofolders(pseudofolder, container) do
        list_pseudofolders(pseudofolder, container, [])
      end

      def list_pseudofolders(pseudofolder, container, opts) do
        nested? = Keyword.get(opts, :nested, :false)
        pseudofolder = Openstex.Utils.ensure_has_leading_slash(pseudofolder)
        |> Openstex.Utils.remove_if_has_trailing_slash()
        conn = V1.get_objects_in_folder(pseudofolder, container, get_account())
        case nested? do
          :true ->
            recurse_pseudofolders(conn, container, get_account())
          :false ->
            case client().request(conn) do
              {:ok, conn} ->
                body = if conn.response.body == "", do: [], else: conn.response.body
                folders = filter_non_pseudofolders(body)
                {:ok, folders}
              {:error, conn} ->
                {:error, conn}
            end
        end
      end

      def list_pseudofolders!(container) do
        list_pseudofolders!("", container, [nested: :true])
      end

      def list_pseudofolders!(pseudofolder, container) do
        list_pseudofolders!(pseudofolder, container, [])
      end

      def list_pseudofolders!(pseudofolder, container, opts) do
        case list_pseudofolders(pseudofolder, container, opts) do
          {:ok, objects} -> objects
          {:error, conn} -> raise(Openstex.ResponseError, conn: conn)
        end
      end

      def pseudofolder_exists?("", container), do: :false
      def pseudofolder_exists?("/", container), do: :false
      def pseudofolder_exists?(pseudofolder, container) do
        pseudofolder = Openstex.Utils.remove_if_has_trailing_slash(pseudofolder)
        |> Openstex.Utils.ensure_has_leading_slash()
        with split_list when split_list != [] <- Path.split(pseudofolder),
             one_level_up <- List.delete_at(split_list, -1),
             one_level_up <- (one_level_up == []) && "" || Path.join(one_level_up),
             {:ok, pseudofolders} when pseudofolders != [] <- list_pseudofolders(one_level_up, container, []) do
          Enum.member?(pseudofolders, pseudofolder)
        else
          [] -> :false
          {:ok, pseudofolders} when pseudofolders == [] -> :false
          {:error, conn} -> raise(Openstex.ResponseError, conn: conn)
        end
      end

      def delete_pseudofolder(pseudofolder, container) do
        if pseudofolder_exists?(pseudofolder, container) do
          responses = list_objects!(pseudofolder, container, [nested: :true])
          |> Enum.map(fn(obj) ->
            conn = V1.delete_object(obj, container, get_account())
            case client().request(conn) do
              {:ok, _conn} -> :ok
              {:error, _conn} -> {:error, obj}
            end
          end)
          failed_deletes = Enum.filter(responses,
            fn(resp) ->
              case resp do
                :ok -> :false
                _ -> :true
              end
            end
          )
          |> Enum.map(fn(resp) ->
            Tuple.to_list(resp) |> List.last()
          end)
          if failed_deletes == [] do
            :ok
          else
            {:error, failed_deletes} # failed_deletes = objects which were not deleted
          end
        else
          :ok
        end
      end

      def generate_temp_url(container, server_object, opts \\ []) do
        temp_url_key = get_account_tempurl_key(:key1)
        temp_url_expires_after = Keyword.get(opts, :temp_url_expires_after, (5 * 60))
        temp_url_filename = Keyword.get(opts, :temp_url_filename, :false)
        temp_url_inline = Keyword.get(opts, :temp_url_inline, :false)
        temp_url_method = Keyword.get(opts, :temp_url_method, "GET")
        path = "/v1/#{get_account()}/#{container}/#{server_object}"
        temp_url_expiry = :os.system_time(:seconds) + temp_url_expires_after
        temp_url_sig = Openstex.Utils.gen_tempurl_signature(temp_url_method, temp_url_expiry, path, temp_url_key)

        qs_map = Map.put(%{}, :temp_url_sig, temp_url_sig)
        |> Map.put(:temp_url_expires, temp_url_expiry)
        qs_map = if temp_url_filename, do: Map.put(qs_map, :filename, temp_url_filename), else: qs_map

        url = client().swift().get_public_url() <> "/#{container}/#{server_object}" <> "?" <> URI.encode_query(qs_map)
        if temp_url_inline, do: url <> "&inline", else: url
      end


      # Private


      defp get_objects_only_in_pseudofolder(obj, container, account) do
        obj = Openstex.Utils.ensure_has_leading_slash(obj)
        |> Openstex.Utils.remove_if_has_trailing_slash()
        request = V1.get_objects_in_folder(obj, container, account)
        case client().request(request) do
          {:ok, conn} ->
            objects = conn.response.body
            |> Enum.filter(fn(e) -> Map.has_key?(e, "subdir") == :false end)
            |> Enum.map(fn(e) ->  e["name"] end)
            {:ok, objects}
          {:error, conn} ->
            {:error, conn}
        end
      end

      defp get_pseudofolders(obj, container, account) do
        obj = Openstex.Utils.ensure_has_leading_slash(obj)
        |> Openstex.Utils.remove_if_has_trailing_slash()
        V1.get_objects_in_folder(obj, container, account)
        |> client().request!()
        |> Map.get(:response) |> Map.get(:body)
        |> Enum.filter(fn(e) -> e["subdir"] != :nil end)
        |> Enum.map(fn(e) ->  e["subdir"] end)
      end

      defp filter_non_pseudofolders(objects) do
        Enum.filter(objects, fn(e) -> e["subdir"] != :nil end)
        |> Enum.map(fn(e) ->  e["subdir"] end)
      end

      defp recurse_pseudofolders(%HTTPipe.Conn{} = conn, container, account) do
        case client().request(conn) do
          {:ok, conn} ->
            folders = filter_non_pseudofolders(conn.response.body)
            pseudofolders = recurse_pseudofolders(folders, container, account)
            |> Enum.filter(fn(e) -> e != "" end) # filters out the very top-level root folder "/"
            |> Enum.map(fn(e) -> e end)
            {:ok, pseudofolders}
          {:error, conn} ->
            {:error, conn}
        end
      end
      defp recurse_pseudofolders(folder, container, account) when is_binary(folder) do
        recurse_pseudofolders([folder], [], container, account)
      end
      defp recurse_pseudofolders(folders, container, account) when is_list(folders) do
        recurse_pseudofolders(folders, [], container, account)
      end
      defp recurse_pseudofolders([ f | folders ], acc, container, account) do
        deeper_nested = get_pseudofolders(f, container, account)
        case deeper_nested == [] do
          :true ->
            acc = [ f | acc ]
            recurse_pseudofolders(folders, acc, container, account)
          :false ->
            acc = [ f | acc ]
            recurse_pseudofolders(folders, acc, container, account)
            |> Enum.concat(recurse_pseudofolders(deeper_nested, [], container, account))
        end
      end
      defp recurse_pseudofolders([], acc, container, account) do
        acc
      end

      defp put_temp_url_key(key, header, key_number) do
        %HTTPipe.Request{method: :post, url: get_account()}
        |> client().prepare_request()
        |> HTTPipe.Conn.put_req_header(header, key)
        |> client().request!()

        # update config genserver with new key
        case key_number do
          :key1 ->
            client().config().set_account_temp_url_key1(client(), key)
          :key2 ->
            client().config().set_account_temp_url_key2(client(), key)
        end
      end

    end

  end   # end of __using__ macro


  @doc ~s"""
  Gets the public url (storage_url) for the swift endpoint.

  ## Example

      account = Client.Swift.get_public_url()
  """
  @callback get_public_url() :: String.t


  @doc ~s"""
  Gets the swift account string for the swift client.

  ## Example

      account = Client.Swift.get_account()
  """
  @callback get_account() :: String.t | no_return


  @doc ~s"""
  Gets the swift endpoint for a given swift client. Returns the publicUrl
  of the endpoint with the account string removed.

  ## Example

      endpoint = Client.Swift.get_endpoint()
  """
  @callback get_endpoint() :: String.t | no_return


  @doc ~s"""
  Gets the tempurl key - at an account level.

  ## Example

      tempurl_key = Client.Swift.get_account_tempurl_key(:key1)
  """
  @callback get_account_tempurl_key(key_number :: atom) :: String.t | no_return


  @doc ~s"""
  Sets the account tempurl key - at an account level.

  ## Example

      :ok = Client.Swift.set_account_temp_url_key(:key1, "SECRET_TEMPURL_KEY")
  """
  @callback set_account_temp_url_key(key_number :: atom, key :: String.t) :: :ok | no_return


  @doc ~s"""
  Deletes an object from a given container

  ## Example

      server_object = "/openstex_tests/nested/test_file.json"
      case Client.Swift.delete_object(server_object, "default_container") do
        {:ok, conn} -> ...
        {:error, conn} -> ...
      end
  """
  @callback delete_object(server_object :: String.t, container :: String.t)
            :: {:ok, HTTPipe.Conn.t} | {:error, HTTPipe.Conn.t}


  @doc ~s"""
  Deletes an object from a given container

  ## Example

      server_object = "/openstex_tests/nested/test_file.json"
      :ok = Client.Swift.delete_object!(server_object, "default_container") do
  """
  @callback delete_object!(server_object :: String.t, container :: String.t) :: :ok |no_return


  @doc ~s"""
  Upload a file.

  ## Arguments

  - `file`: The path of the file on the client machine.
  - `server_object`: The path of the file on the openstack swift server
  - `container`: The name of the container.
  - `upload_opts`: See `Openstex.Swift.V1.create_object/4`

  ## Example

      file = "/priv/test_file.json"
      server_object = "/openstex_tests/nested/test_file.json"
      case Client.Swift.upload_file(file, server_object, "default_container") do
        {:ok, conn} -> ...
        {:error, conn} -> ...
      end
  """
  @callback upload_file(client_path :: String.t, server_path :: String.t, container :: String.t, opts :: list)
            :: {:ok, HTTPipe.Conn.t} |
               {:error, HTTPipe.Conn.t}


  @doc ~s"""
  Upload a file. See `upload_file/4`. Returns `:ok` if upload suceeeded,
  otherwise raises an error.

  ## Example

      file = "/priv/test_file.json"
      server_object = "/openstex_tests/nested/test_file.json"
      :ok = Client.Swift.upload_file!(file, server_object, "default_container") do
  """
  @callback upload_file!(client_path :: String.t, server_path :: String.t, container :: String.t, opts :: list)
            :: :ok |
               no_return


  @doc ~s"""
  Download a file. The body of the response contains the binary object (file).

  ## Arguments

  - `server_object`: The path of the file on the openstack swift server.
  - `container`: The name of the container.

  ## Example

      server_object = "/openstex_tests/nested/test_file.json"
      container = "default_container"
      case Client.Swift.download_file(server_object, container) do
        {:ok, conn} -> object = conn.response.body
        {:error, conn} -> ...
      end
  """
  @callback download_file(server_path :: String.t, container :: String.t)
            :: {:ok, HTTPipe.Conn.t} |
               {:error, HTTPipe.Conn.t}


  @doc ~s"""
  Downloading a file. Returns the binary object (file) or raises an error.
  See `download_file/2`.

  ## Example

      server_object = "/openstex_tests/nested/test_file.json"
      container = "default_container"
      object = Client.Swift.download_file!(server_object, container)
  """
  @callback download_file!(String.t, String.t) :: :binary | no_return


  @doc ~s"""
  Lists all containers.

  ## Example

      case Client.Swift.list_containers() do
        {:ok, conn} -> containers = conn.response.body
        {:error, conn} -> ...
      end
  """
  @callback list_containers() :: {:ok, list} | {:error, map}


  @doc ~s"""
  Lists all containers. Returns a `list` or raises an error.

  ## Example

      containers = Client.Swift.list_containers!()
  """
  @callback list_containers!() :: list| no_return


  @doc ~s"""
  Lists all objects within a container.

  ## Arguments

  - `container`: The name of the container.

  ## Example

      case Client.Swift.list_objects() do
        {:ok, conn} -> objects = conn.response.body
        {:error, conn} -> ...
      end
  """
  @callback list_objects(container :: String.t) :: {:ok, list} | {:error, map}


  @doc ~s"""
  Lists all the objects in a container or raises an error.  See `list_objects/3`.

  ## Example

      objects = Client.Swift.list_objects!()
  """
  @callback list_objects!(container :: String.t) :: list | no_return


  @doc ~s"""
  Lists objects within a pseudofolder in a container. Optionally list objects in
  recursively nested pseudofolders.

  ## Arguments

  - `pseudofolder`: The pseudofolder in which to list the objects.
  - `container`: The container in which to find the objects.
  - `nested`: defaults to `:false`. If `:true`, returns all objects in
  recursively nested pseudofolders. If `:false`, returns all objects at
  one level deep and ignores objects within nested pseudofolders.

  ## Notes

  - Excludes pseudofolders from the results. Pseudofolders are filtered out of the results and
   only binary objects are included in the results.
  - If no pseudofolder name is entered, `pseudofolder` defaults to `""`, thereby getting all objects in
  the container.

  ## Example - (1)

  Return all objects in the `"test_folder/"` but not objects in nested pseudofolders.

      case Client.Swift.list_objects("test_folder/", "default", [nested: :false]) do
        {:ok, conn} -> objects = conn.response.body
        {:error, conn} -> ...
      end

  ## Example - (2)

  Return all objects in the `"test_folder/"` and all recursively nested pseudofolders.

      case Client.Swift.list_objects("test_folder/", "default", [nested: :true]) do
        {:ok, conn} -> objects = conn.response.body
        {:error, conn} -> ...
      end

  ## Example - (3)

  Returns all objects in the `"default_container"` container.

      case Client.Swift.list_objects("", "default_container", [nested: :true]) do
        {:ok, conn} -> objects = conn.response.body
        {:error, conn} -> ...
      end
  """
  @callback list_objects(pseudofolder :: String.t, container :: String.t, opts :: list)
            :: {:ok, list} |
               {:error, HTTPipe.Conn.t}


  @doc ~s"""
  Lists objects within a pseudofolder in a container or raises an error.
  Optionally include objects in nested pseudofolders. See `list_objects/3`.

  ## Example

  Return all objects in the `"test_folder/"` but not objects in nested pseudofolders.

      objects_first_level_only = Client.Swift.list_objects!("test_folder/", "default", [nested: :false])
  """
  @callback list_objects!(pseudofolder :: String.t, container :: String.t, opts :: list)
            :: {:ok, list} |
               no_return


  @doc ~s"""
  Lists all pseudofolders including nested pseudofolders in a container.
  Also, see `list_pseudofolders/3`.

  ## Arguments

  - `container`: The name of the container.

  ## Example

      case Client.Swift.list_pseudofolders("default") do
        {:ok, conn} -> pseudofolders = conn.response.body
        {:error, conn} -> ...
      end
  """
  @callback list_pseudofolders(container :: String.t) :: {:ok, list} | {:error, HTTPipe.Conn.t}


  @doc ~s"""
  Lists pseudofolders one level deep in a given pseudofolder.
  Also, see `list_pseudofolders/3`.

  ## Arguments

  - `pseudofolder`: The pseudofolder in which to search for one level deep subfolders.
  - `container`: The name of the container.

  ## Example

      case Client.Swift.list_pseudofolders("products/categories/", "products_container") do
        {:ok, conn} -> pseudofolders = conn.response.body
        {:error, conn} -> ...
      end
  """
  @callback list_pseudofolders(pseudofolder :: String.t, container :: String.t)
            :: {:ok, list} |
               {:error, HTTPipe.Conn.t}


  @doc ~s"""
  List pseudofolders within a pseudofolder.

  ## Arguments

  - `pseudofolder`: The pseudofolder in which to search for other pseudofolders
  - `container`: The name of the container.
  - `nested`, defaults to :false
  - `nested`: defaults to `:false`. If `:true`, returns all pseudofolders in
  recursively nested pseudofolders. If `:false`, returns all pseudofolders at
  one level deep and ignores pseudofolders within nested pseudofolders.

  ## Notes

  - If no pseudofolder is entered, then pseudofolder defaults to `"" ` which in turn results in all
  pseudofolders being fetched one level deep at the root level.
  - Traverses as deep as the most nested pseudofolder if `nested: :true`.
  - Excludes non-pseudofolder objects from the results, in other words, binary objects will be filtered
  from the results and only pseudofolders are returned.


  ## Example - (1)

  Return all pseudofolders in the `"test_folder/"` but not objects in nested pseudofolders.

      case Client.Swift.list_pseudofolders("test_folder/", "default", [nested: :false]) do
        {:ok, conn} -> pseudofolders = conn.response.body
        {:error, conn} -> ...
      end

  ## Example - (2)

  Return all pseudofolders in the `"test_folder/"` one level deep. `nested` defaults to `:false`

      case Client.Swift.list_pseudofolders("test", "default") do
        {:ok, conn} -> pseudofolders = conn.response.body
        {:error, conn} -> ...
      end

  ## Example - (3)

  Gets all the pseudofolders in the container and traverses to the deepest nested pseudofolders.

      case Client.Swift.list_pseudofolders("", "default_container", [nested: :true]) do
        {:ok, conn} -> pseudofolders = conn.response.body
        {:error, conn} -> ...
      end
  """
  @callback list_pseudofolders(pseudofolder :: String.t, container :: String.t, opts :: list)
            :: {:ok, list} |
               {:error, map}


  @doc ~s"""
  Lists all pseudofolders including nested pseudofolders in a container. See `list_pseudofolders!/3`

  ## Arguments

  - `container`: The name of the container in which to list the pseudofolders.

  ## Example

      pseudofolders = Client.Swift.list_pseudofolders!("products_container")
  """
  @callback list_pseudofolders!(String.t) :: list | no_return


  @doc ~s"""
  Lists pseudofolders one level deep from a given pseudofolder.
  Also, see `list_pseudofolders!/3`.

  ## Arguments

  - `pseudofolder`: The pseudofolder to be checked for having subfolders.
  - `container`: The name of the container.

  ## Example

      categories = Client.Swift.list_pseudofolders!("products/cateogores/", "products_container")
  """
  @callback list_pseudofolders!(pseudofolder :: String.t, container :: String.t) :: list | no_return


  @doc ~s"""
  Lists all pseudofolders within a pseudofolder or raises an error.
  See `list_pseudofolders/3`.
  """
  @callback list_pseudofolders!(pseudofolder :: String.t, container :: String.t, opts :: list) :: list| no_return


  @doc ~s"""
  Checks if a pseudofolder exists.

  ## Arguments

  - `pseudofolder`: The pseudofolder whose existence is to be checked.
  - `container`: The name of the container.

  ## Example

      case Client.Swift.pseudofolder_exists?("products/cateogores/", "products_container") do
        :true -> Client.Swift.list_pseudofolders!("products/cateogores/", "products_container")
        :false -> ...
      end
  """
  @callback pseudofolder_exists?(pseudofolder :: String.t, container :: String.t) :: boolean | no_return


  @doc ~s"""
  Deletes all objects in a pseudofolder effectively deleting the pseudofolder itself.

  ## Arguments

  - `pseudofolder`: The pseudofolder to be deleted.
  - `container`: The container in which to delete the pseudofolder.

  ## Notes

  - Returns `:ok` on success or if pseudofolder did not exist in the first place.
  - Returns `{:error, list}` if some objects were not deleted where `list` represents
  the objects for which deletion failed.

  ## Example

    case Client.delete_pseudofolder("products/", "container_name") do
      :ok -> IO.puts("objects deleted")
      {:error, items} -> Enum.each(items, &IO.inspect/1)
    end
  """
  @callback delete_pseudofolder(pseudofolder :: String.t, container :: String.t) :: :ok | {:error, list}


  @doc """
  Generates a tempurl for an object.

  ## Arguments

  - `container`: container in which the object is found.
  - `server_object`: filename under which the file will be stored on the
  openstack object storage server.defaults to the `client_object_pathname`
  if none given.
  - `opts`:

    - `temp_url_expires_after`: Sets the length of time for which the signature
    to the public link will remain valid. Adds the `temp_url_expires` query string to the url.
    The unix epoch time format is used. Defaults to 5 minutes from current time if `temp_url` is `:true`.
    Otherwise, it can be set by adding the time in seconds from now for which the link
    should remain valid. Eg 10 days => (10 * 24 * 60 * 60)

    - `temp_url_filename`: Defaults to `:false`. Swift automatically generates filenames for temp_urls
    but this option will allow custom names to be added.
    Works by adding the `filename` query string to the url.

    - `temp_url_inline`: Defaults to `:false`. If set to `:true`, the file is not automatically downloaded
    by the browser and instead the `&inline' query string is added to the url.

    - `temp_url_method: Defaults to `"GET"` but can be set to `"PUT"`.

  ## Notes

  - The client should have a `:account_temp_url_key` option already specified in `config.exs` since
  this is needed for generating temp_urls.
  - Read more about tempurls at this link
  `https://docs.openstack.org/developer/swift/api/temporary_url_middleware.html`

  ## Example

      temp_url = Client.Swift.generate_temp_url("test_container", "test_file.txt")
  """
  @callback generate_temp_url(container :: String.t, server_path :: String.t, opts :: list) :: String.t


end
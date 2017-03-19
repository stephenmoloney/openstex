defmodule Openstex.Swift.V1.Helpers do
  @moduledoc ~s"""
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
          client().keystone().identity(client())
          |> Map.get(:service_catalog)
          |> Enum.find(fn(%Identity.Service{} = service) ->
            service.name == client().config().swift_service_name() && service.type == client().config().swift_service_type()
          end)
          |> Map.get(:endpoints)
          |> Enum.find(fn(%Identity.Endpoint{} = endpoint) ->  endpoint.region == client().config().swift_region(client) end)
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

        @doc ~s"""
        Helper function to simplify the process of uploading a file.

        ## Arguments

        - `file`: The path of the file on the client machine.
        - `server_object`: The path of the file on the openstack swift server
        - `container`: The name of the container.
        - `upload_opts`: See `Openstex.Swift.V1.create_object/4`

        ## Example

            file = "/priv/test_file.json"
            server_object = "ex_hubic_tests/nested/test_file.json"
            Client.Swift.upload_file(file, server_object, "default")
        """
        @spec upload_file(String.t, String.t, String.t, list) :: {:ok, Response.t} | {:error, Response.t}
        def upload_file(file, server_object, container, upload_opts \\ []) do
          upload_opts = upload_opts ++ [server_object: server_object]
          conn = V1.create_object(container, get_account(), file, upload_opts)
          client().request(conn)
        end


        @doc ~s"""
        Helper function to simplify the process of uploading a file. See `upload_file/5`. Returns :ok
        if upload suceeeded or raises and error otherwise.
        """
        @spec upload_file!(String.t, String.t, String.t, list) :: :ok | no_return
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


        @doc ~s"""
        Helper function to simplify the process of downloading a file. The body of the response
        contains the binary object (file).

        ## Arguments

        - `server_object`: The path of the file on the openstack swift server
        - `container`: The name of the container.

        ## Example

            server_object = "/ex_hubic_tests/nested/test_file.json"
            Client.Swift.download_file(server_object, "default")
        """
        @spec download_file(String.t, String.t) :: {:ok, Response.t} | {:error, Response.t}
        def download_file(server_object, container) do
          conn = V1.get_object(server_object, container, get_account())
          client().request(conn)
        end


        @doc ~s"""
        Helper function to simplify the process of downloading a file. Returns the binary object (file)
        or raises an error. See `download_file/3`.
        """
        @spec download_file!(String.t, String.t) :: :binary | no_return
        def download_file!(server_object, container) do
          case download_file(server_object, container) do
            {:ok, conn} -> conn.response.body
            {:error, conn} ->
              conn = V1.get_object(server_object, container, get_account())
              raise(Openstex.ResponseError, conn: conn)
          end
        end


        @doc ~s"""
        Lists all containers.
        """
        @spec list_containers() :: {:ok, list} | {:error, map}
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


        @doc ~s"""
        Lists all containers.
        """
        @spec list_containers!() :: list | no_return
        def list_containers!() do
          case list_containers() do
            {:ok, containers} -> containers
            {:error, conn} -> raise(Openstex.ResponseError, conn: conn)
          end
        end


        @doc ~s"""
        Lists all objects within a container.

        ## Arguments

        - `container`: The name of the container.
        """
        @spec list_objects(String.t) :: {:ok, list} | {:error, map} | {:error, String.t}
        def list_objects(container) do

        end


        @doc ~s"""
        Lists all objects within a container.

        ## Arguments

        - `container`: The name of the container.
        """
        @spec list_objects!(String.t) :: list | no_return
        def list_objects!(container) do
          list_objects!("", container, [nested: :true])
        end


        @doc ~s"""
        Lists objects within a pseudofolder in a container. Optionally include objects in nested
        pseudofolders.

        ## Arguments

        - `pseudofolder`: The pseudofolder in which to list the objects.
        - `container`: The container in which to find the objects.
        - `nested`, defaults to :false

            [nested: true] => returns all objects in nested pseudofolders also.

            [nested: false] => returns all objects at the top level and ignores objects witihin
            nested pseudofolders.

        ## Notes

        - Excludes pseudofolders from the results.
        - If no pseudofolder name is entered, `pseudofolder` defaults to `""`, thereby getting all objects in
        the container
        - Returns the object name.
        - Returns files
        - Does not list pseudofolders

        ## Example

        Returns all objects in the `"test_folder/"` but not objects in nested pseudofolders
            Client.Swift.list_objects("test_folder/", "default", [nested: :false])

        Returns all objects in the `"test_folder/"` and all nested pseudofolders.
            Client.Swift.list_objects("test_folder/", "default", [nested: :true])

        Returns all objects in the `"default"` container
          Client.Swift.list_objects("default", [nested: :true])
        """
        @spec list_objects(String.t, String.t, list) :: {:ok, list} | {:error, map} | {:error, String.t}
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
            :false -> {:error, "Unsuccessful request, #{container} does not seem to exist."}
            {:error, conn} -> {:error, conn}
          end
        end
        def list_objects(pseudofolder, container, [nested: :false]) do
          case  get_objects_only_in_pseudofolder(pseudofolder, container, get_account()) do
            {:ok, objects} -> {:ok, objects}
            {:error, conn} -> {:error, conn}
          end
        end
        def list_objects(pseudofolder, container, []) do
          list_objects(pseudofolder, container, [nested: :false])
        end


        @doc ~s"""
        Lists objects within a pseudofolder in a container or raises an error. Optionally include objects in nested
        pseudofolders. see `list_objects/3`
        """
        @spec list_objects!(String.t, String.t, list) :: {:ok, list} | no_return
        def list_objects!(folder, container, opts \\ []) do
          case list_objects(folder, container, opts) do
            {:ok, objects} -> objects
            {:error, conn} -> raise(Openstex.ResponseError, conn: conn)
          end
        end


        @doc ~s"""
        Lists all pseudofolders including nested pseudofolders in a container. See `list_pseudofolders/3`

        ## Arguments

        - `container`: The name of the container in which to list the pseudofolders.
        """
        @spec list_pseudofolders(String.t) :: {:ok, list} | {:error, Openstex.Response.t}
        def list_pseudofolders(container) do
          list_pseudofolders("", container, [nested: :true])
        end


        @doc ~s"""
        Lists pseudofolders at the top level in a given pseudofolder. See `list_pseudofolders/3`

        ## Arguments

        - `pseudofolder`: The pseudofolder in which to search for other top-level pseudofolders
        - `container`: The name of the container in which to list the pseudofolders.
        """
        @spec list_pseudofolders(String.t, String.t) :: {:ok, list} | {:error, Openstex.Response.t}
        def list_pseudofolders(pseudofolder, container) do
          list_pseudofolders(pseudofolder, container, [])
        end


        @doc ~s"""
        Lists all pseudofolders within a pseudofolder in a container.

        ## Arguments

        - `pseudofolder`: The pseudofolder in which to search for other pseudofolders
        - `container`: The name of the container in which to list the pseudofolders.
        - `nested`, defaults to :false

            [nested: true] => returns all objects in nested pseudofolders also.

            [nested: false] => returns all objects at the top level and ignores objects witihin
            nested pseudofolders.


        ## Notes

        - If no pseudofolder is entered, then pseudofolder defaults to `"" ` which in turn results in all
        pseudofolders being fetched one level deep at the root level.
        - Returns the pseudofolders by name.
        - Traverses as deep as the most nested folder beyond the passed folder to get all folders.
        - Excludes non-pseudofolder objects from the results.

        ## Example

        Gets all pseudofolders in the `"test_folder/"` pseudofolder one level deep (top level)
            Client.Swift.list_pseudofolders("test_folder/", "default")

        Gets all pseudofolders in the `"test/"` pseudofolder one level deep (top level)
            Client.Swift.list_pseudofolders("test", "default")

        Gets all the pseudofolders in the container and traverse to the deepest nested pseudofolders
            Client.Swift.list_pseudofolders(default", [nested: :true])
        """
        @spec list_pseudofolders(String.t, String.t, list) :: {:ok, list} | {:error, HTTPipe.Conn.t}
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


        @doc ~s"""
        Lists all pseudofolders including nested pseudofolders in a container. See `list_pseudofolders!/3`

        ## Arguments

        - `container`: The name of the container in which to list the pseudofolders.
        """
        @spec list_pseudofolders!(String.t) :: list | no_return
        def list_pseudofolders!(container) do
          list_pseudofolders!("", container, [nested: :true])
        end


        @doc ~s"""
        Lists pseudofolders at the top level in a given pseudofolder. See `list_pseudofolders!/3`

        ## Arguments

        - `pseudofolder`: The pseudofolder in which to search for other top-level pseudofolders
        - `container`: The name of the container in which to list the pseudofolders.
        """
        @spec list_pseudofolders!(String.t, String.t) :: list | no_return
        def list_pseudofolders!(pseudofolder, container) do
          list_pseudofolders!(pseudofolder, container, [])
        end


        @doc ~s"""
        Lists all pseudofolders within a pseudofolder in a container or raises an error. See `list_pseudofolders/3`.
        """
        @spec list_pseudofolders!(String.t, String.t, list) :: list| no_return
        def list_pseudofolders!(pseudofolder, container, opts) do
          case list_pseudofolders(pseudofolder, container, opts) do
            {:ok, objects} -> objects
            {:error, conn} -> raise(Openstex.ResponseError, conn: conn)
          end
        end


        @doc ~s"""
        Checks if a pseudofolder exists.

        ## Arguments

        - `pseudofolder`: The pseudofolder whose existence is to be checked.
        - `container`: The name of the container in which to list the pseudofolders.
        """
        @spec pseudofolder_exists?(String.t, String.t) :: boolean | no_return
        def pseudofolder_exists?(pseudofolder, container) do
          case list_objects(pseudofolder, container) do
            {:ok, []} ->
              :false
            {:error, conn} ->
              raise(Openstex.ResponseError, conn: conn)
            {:ok, list} ->
              :true
          end
        end


        @doc ~s"""
        Deletes all objects in a pseudofolder effectively deleting the pseudofolder itself.

        ## Arguments

        - `pseudofolder`: The pseudofolder to be deleted.
        - `container`: The container in which to delete the pseudofolder.

        ## Notes

        - Returns `:ok` anyways even if pseudofolder did not exist in the first place.
        - Returns `{:error, list}` if some objects were not deleted where `list` represents
        the objects for which deletion failed.
        """
        @spec delete_pseudofolder(String.t, String.t) :: :ok | {:error, list}
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
            failed_deletes = Enum.filter_map(responses,
              fn(resp) ->
                case resp do
                  :ok -> :false
                  :false -> :true
                end
              end,
              fn(resp) ->
                Tuple.to_list(resp) |> List.last()
              end
            )
            if failed_deletes == [] do
              :ok
            else
              {:error, failed_deletes}
            end
          else
            :ok
          end
        end


        @doc """
        Generates a tempurl for an object.

        ## Example

            Client.Swift.generate_temp_url("test_container", "test_file.txt", [])

        ## Arguments

        - `container`: container in which the object is found.
        - `server_object`: filename under which the file will be stored on the openstack object storage server. defaults to the `client_object_pathname` if none given.
        - `opts`:
          - `temp_url_expires_after`: Sets the length of time for which the signature to the public link will remain valid. Adds the `temp_url_expires` query string to the url.
          The unix epoch time format is used. Defaults to 5 minutes from current time if `temp_url` is :true. Otherwise, it can be set by adding the time in seconds from now for which the link
          should remain valid. Eg 10 days => (10 * 24 * 60 * 60)
          - `temp_url_filename`: Defaults to `:false`. Swift automatically generates filenames for temp_urls but this option will allow custom names to be added. Works by adding the `filename` query string to the url.
          - `temp_url_inline`: Defaults to `:false`. If set to `:true`, the file is not automatically downloaded by the browser and instead the `&inline' query string is added to the url.
          - `temp_url_method: Defaults to `"GET"` but can be set to `"PUT"`.


        ## Notes

        - The client should have a `:account_temp_url_key` option already setup in `config.exs`.
        """
        @spec generate_temp_url(String.t, String.t, list) :: String.t
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
              |> Enum.filter_map(
                fn(e) -> Map.has_key?(e, "subdir") == :false end,
                fn(e) ->  e["name"] end
              )
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
          |> Enum.filter_map(
            fn(e) -> e["subdir"] != :nil end,
            fn(e) ->  e["subdir"] end
          )
        end


        defp filter_non_pseudofolders(objects) do
          Enum.filter_map(objects,
            fn(e) -> e["subdir"] != :nil end,
            fn(e) ->  e["subdir"] end
          )
        end


        defp recurse_pseudofolders(%HTTPipe.Conn{} = conn, container, account) do
          case client().request(conn) do
            {:ok, conn} ->
              folders = filter_non_pseudofolders(conn.response.body)
              pseudofolders = recurse_pseudofolders(folders, container, account)
              |> Enum.filter_map(
                fn(e) -> e != "" end,
                fn(e) -> e end
              ) # filters out the very top-level root folder "/"
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
    end


    @doc "Gets the public url (storage_url) for the swift endpoint"
    @callback get_public_url() :: String.t

    @doc "Gets the swift account string for the swift client"
    @callback get_account() :: String.t

    @doc "Gets the swift endpoint for a given swift client. Returns the publicUrl of the endpoint with the account string removed."
    @callback get_endpoint() :: String.t

    @doc "Gets the tempurl key - at an account level"
    @callback get_account_tempurl_key(keynumber :: atom) :: String.t

    @doc "Sets the account tempurl key - at an account level"
    @callback set_account_temp_url_key(key_number :: atom, key :: String.t) :: :ok

    @doc "Deletes an object from a given container"
    @callback delete_object(server_object :: String.t, container :: String.t)
      :: {:ok, HTTPipe.Conn.t} | {:error, HTTPipe.Conn.t}

    @doc "Deletes an object from a given container"
    @callback delete_object!(server_object :: String.t, container :: String.t)
      :: {:ok, HTTPipe.Conn.t} | no_return

    @doc ~s"""
    Helper function to simplify the process of uploading a file.

    ## Arguments

    - `file`: The path of the file on the client machine.
    - `server_object`: The path of the file on the openstack swift server
    - `container`: The name of the container.

    ## Example

        file = "/priv/test_file.json"
        server_object = "/ex_hubic_tests/nested/test_file.json"
        Client.Swift.upload_file(file, server_object, "default")
    """
    @callback upload_file(String.t, String.t, String.t, list) :: {:ok, Response.t} | {:error, Response.t}


    @doc ~s"""
    Helper function to simplify the process of uploading a file. See `upload_file/4`. Returns :ok
    if upload suceeeded or raises and error otherwise.
    """
    @callback upload_file!(String.t, String.t, String.t, list) :: :ok | no_return


    @doc ~s"""
    Helper function to simplify the process of downloading a file. The body of the response
    contains the binary object (file).

    ## Arguments

    - `server_object`: The path of the file on the openstack swift server
    - `container`: The name of the container.

    ## Example

        server_object = "/ex_hubic_tests/nested/test_file.json"
        Client.Swift.download_file(server_object, "default", [recv_timeout: (60000 * 1)]) # allow 1 min for download
    """
    @callback download_file(String.t, String.t) :: {:ok, Response.t} | {:error, Response.t}



    @doc ~s"""
    Helper function to simplify the process of downloading a file. Returns the binary object (file)
    or raises an error. See `download_file/3`.
    """
    @callback download_file!(String.t, String.t) :: :binary | no_return


    @doc ~s"""
    Lists objects within a pseudofolder in a container. see `list_objects/3`

    ## Arguments

    - `container`: The name of the container.
    """
    @callback list_objects(String.t) :: {:ok, list} | {:error, map}


    @doc ~s"""
    Lists all the objects in a container or raises an error.  See `list_objects/3`.
    """
    @callback list_objects!(String.t) :: list | no_return


    @doc ~s"""
    Lists objects within a pseudofolder in a container. Optionally include objects in nested
    pseudofolders.

    ## Arguments

    - `pseudofolder`: The pseudofolder in which to list the objects.
    - `container`: The container in which to find the objects.
    - `nested`, defaults to :false

        [nested: true] => returns all objects in nested pseudofolders also.

        [nested: false] => returns all objects at the top level and ignores objects witihin
        nested pseudofolders.

    ## Notes

    - Excludes pseudofolders from the results.
    - If no pseudofolder name is entered, `pseudofolder` defaults to `""`, thereby getting all objects in
    the container
    - Returns the object name.
    - Returns files
    - Does not list pseudofolders

    ## Example

    Returns all objects in the `"test_folder/"` but not objects in nested pseudofolders
        Client.Swift.list_objects("test_folder/", "default", [nested: :false])

    Returns all objects in the `"test_folder/"` and all nested pseudofolders.
        Client.Swift.list_objects("test_folder/", "default", [nested: :true])

    Returns all objects in the `"default"` container
        Client.Swift.list_objects("default", [nested: :true])
    """
    @callback list_objects(String.t, String.t, list) :: {:ok, list} | {:error, map}


    @doc ~s"""
    Lists objects within a pseudofolder in a container or raises an error. Optionally include objects in nested
    pseudofolders. see `list_objects/3`
    """
    @callback list_objects!(String.t, String.t, list) :: {:ok, list} | no_return


    @doc ~s"""
    Lists all pseudofolders including nested pseudofolders in a container. See `list_pseudofolders/3`

    ## Arguments

    - `container`: The name of the container in which to list the pseudofolders.
    """
    @callback list_pseudofolders(String.t) :: {:ok, list} | {:error, Openstex.Response.t}

    @doc ~s"""
    Lists pseudofolders at the top level in a given pseudofolder. See `list_pseudofolders/3`

    ## Arguments

    - `pseudofolder`: The pseudofolder in which to search for other top-level pseudofolders
    - `container`: The name of the container in which to list the pseudofolders.
    """
    @callback list_pseudofolders(String.t, String.t) :: {:ok, list} | {:error, Openstex.Response.t}


    @doc ~s"""
    Lists all pseudofolders within a pseudofolder in a container.

    ## Arguments

    - `pseudofolder`: The pseudofolder in which to search for other pseudofolders
    - `container`: The name of the container in which to list the pseudofolders.
    - `nested`, defaults to :false

        [nested: true] => returns all objects in nested pseudofolders also.

        [nested: false] => returns all objects at the top level and ignores objects witihin
        nested pseudofolders.

    ## Notes

    - If no pseudofolder is entered, then pseudofolder defaults to `"" ` which in turn results in all
    pseudofolders being fetched one level deep at the root level.
    - Returns the pseudofolders by name.
    - Traverses as deep as the most nested folder beyond the passed folder to get all folders.
    - Excludes non-pseudofolder objects from the results.

    ## Example

    Gets all pseudofolders in the `"test_folder/"` pseudofolder one level deep (top level)
        Client.Swift.list_pseudofolders("test_folder/", "default")

    Gets all pseudofolders in the `"test/"` pseudofolder one level deep (top level)
        Client.Swift.list_pseudofolders("test", "default")

    Gets all the pseudofolders in the container and traverse to the deepest nested pseudofolders
        Client.Swift.list_pseudofolders(default", [nested: :true])
    """
    @callback list_pseudofolders(String.t, String.t, list) :: {:ok, list} | {:error, map}


    @doc ~s"""
    Lists all pseudofolders including nested pseudofolders in a container. See `list_pseudofolders!/3`

    ## Arguments

    - `container`: The name of the container in which to list the pseudofolders.
    """
    @callback list_pseudofolders!(String.t) :: list | no_return


    @doc ~s"""
    Lists pseudofolders at the top level in a given pseudofolder. See `list_pseudofolders!/3`

    ## Arguments

    - `pseudofolder`: The pseudofolder in which to search for other top-level pseudofolders
    - `container`: The name of the container in which to list the pseudofolders.
    """
    @callback list_pseudofolders!(String.t, String.t) :: list | no_return


    @doc ~s"""
    Lists all pseudofolders within a pseudofolder in a container or raises an error. See `list_pseudofolders/3`.
    """
    @callback list_pseudofolders!(String.t, String.t, list) :: list| no_return


    @doc ~s"""
    Checks if a pseudofolder exists.

    ## Arguments

    - `pseudofolder`: The pseudofolder whose existence is to be checked.
    - `container`: The name of the container in which to list the pseudofolders.
    """
    @callback pseudofolder_exists?(String.t, String.t) :: boolean | no_return


    @doc ~s"""
    Deletes all objects in a pseudofolder effectively deleting the pseudofolder itself.

    ## Arguments

    - `pseudofolder`: The pseudofolder to be deleted.
    - `container`: The container in which to delete the pseudofolder.

    ## Notes

    - Returns `:ok` anyways even if pseudofolder did not exist in the first place.
    - Returns `{:error, list}` if some objects were not deleted where `list` represents
    the objects for which deletion failed.
    """
    @callback delete_pseudofolder(String.t, String.t) :: :ok | {:error, list}


end

defmodule Openstex.Utils  do
  @moduledoc "Utility functions"

  @doc """
  Put headers for a http_query. If the headers already exist, the new headers will override the old headers.
  """
  @spec put_http_headers(map, map) :: map
  def put_http_headers(%{headers: headers} = http_query, new_headers) when is_map(new_headers) do
    old_headers_map = headers |> Enum.into(%{})
    new_headers_map = Map.merge(old_headers_map, new_headers)
    new_headers = Map.to_list(new_headers_map)
    Map.put(http_query, :headers, new_headers)
  end

  @doc :false
  def ensure_has_leading_slash(folder) do
    case String.last(folder) do
      "/" ->
        folder
      :nil ->
        folder
      _other ->
        folder <> "/"
    end
  end

  @doc :false
  def ensure_has_trailing_slash(folder) do
    case String.first(folder) do
      "/" ->
        folder
      _other ->
        "/" <> folder
    end
  end

  @doc :false
  def remove_if_has_trailing_slash(folder) do
    case String.first(folder) do
      "/" ->
        {"/", folder} = String.split_at(folder, 1)
        folder
      _other ->
        folder
    end
  end

  @doc :false
  defmacro ets_tablename(client) do
    quote do
      "Ets."
      <>
      (
        unquote(client) |> Atom.to_string()
      )
      |> String.to_atom()
    end
  end


  @doc "Generate tempurl Signature for Openstack Swift"
  @spec gen_tempurl_signature(String.t, integer, String.t, String.t) :: String.t
  def gen_tempurl_signature(method, expiry, path, temp_key) do
    hmac_body = "#{method}\n#{Integer.to_string(expiry)}\n#{path}"
    :crypto.hmac(:sha, temp_key, hmac_body) |> Base.encode16(case: :lower)
  end


end

defmodule Openstex.Utils  do
  @moduledoc "Utility functions"


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

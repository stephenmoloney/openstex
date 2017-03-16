defmodule Openstex.Transformation.Auth do
  @moduledoc :false
  @default_headers [{"Content-Type", "application/json; charset=utf-8"}]


  # Public


  @spec apply(HTTPipe.Conn.t, atom) :: HTTPipe.Conn.t
  def apply(%HTTPipe.Conn{request: %HTTPipe.Request{headers: headers}} = conn, client) do
    trans = Map.get(conn, :completed_transformations, [])
    conn =
    Enum.reduce(@default_headers, conn, fn({h_key, h_val}, acc) ->
      HTTPipe.Conn.put_req_header(acc, h_key, h_val, :replace_existing)
    end)
    Enum.reduce(headers, conn, fn({h_key, h_val}, acc) ->
      HTTPipe.Conn.put_req_header(acc, h_key, h_val, :replace_existing)
    end)
    |> HTTPipe.Conn.put_req_header("X-Auth-Token", client.keystone().get_xauth_token(client))
    |> Map.put(:completed_transformations, trans ++ [:auth])
  end



end

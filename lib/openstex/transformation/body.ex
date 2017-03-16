defmodule Openstex.Transformation.Body do
  @moduledoc :false


  # Public

  @spec apply(HTTPipe.Conn.t, binary) :: HTTPipe.Conn.t
  def apply(%HTTPipe.Conn{request: %HTTPipe.Request{}} = conn, body) when is_binary(body) do
    trans = Map.get(conn, :completed_transformations, [])
    request = Map.put(conn.request, :body, body)
    Map.put(conn, :request, request)
    |> Map.put(:completed_transformations, trans ++ [:body])
  end


end

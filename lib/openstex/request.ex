defmodule Openstex.Request do
  @moduledoc :false


  # Public
  @spec request(HTTPipe.Conn.t | HTTPipe.Request.t, atom) :: {:ok, HTTPipe.Conn.t} | {:error, HTTPipe.Conn.t}
  def request(%HTTPipe.Request{} = request, client) do
    Map.put(HTTPipe.Conn.new(), :request, request)
    |> request(client)
  end
  def request(%HTTPipe.Conn{} = conn, client) do
    conn = apply_transformations(conn, client)

    case HTTPipe.Conn.execute(conn) do
      {:ok, conn} ->
        body = parse_body(conn.response)
        resp = Map.put(conn.response, :body, body)
        conn = Map.put(conn, :response, resp)
        if resp.status_code >= 100 and resp.status_code < 400 do
          {:ok, conn}
        else
          {:error, conn}
        end
      {:error, conn} -> {:error, conn}
    end
  end


  # private


  defp parse_body(resp) do
    try do
       resp.body |> Poison.decode!()
    rescue
      _ ->
        resp.body
    end
  end

  @doc :false
  def apply_transformations(conn, :nil), do: conn
  def apply_transformations(conn, client) do
    conn =
    unless (:url in Map.get(conn, :completed_transformations, [])) do
     Openstex.Transformation.Url.apply(conn, client)
    else
      conn
    end
    conn =
    unless (:body in Map.get(conn, :completed_transformations, [])) do
      Openstex.Transformation.Body.apply(conn, "")
    else
      conn
    end
    conn =
    unless (:hackney_options in Map.get(conn, :completed_transformations, [])) do
      Openstex.Transformation.HackneyOptions.apply(conn, client)
    else
      conn
    end
    unless (:auth in Map.get(conn, :completed_transformations, [])) do
      Openstex.Transformation.Auth.apply(conn, client)
    else
      conn
    end
  end

end

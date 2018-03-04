defmodule Openstex.Request do
  @moduledoc false
  alias HTTPipe.Conn
  alias Openstex.Transformation.{Auth, Body, HackneyOptions, Url}

  # Public
  @spec request(Conn.t() | HTTPipe.Request.t(), atom) :: {:ok, Conn.t()} | {:error, Conn.t()}
  def request(%HTTPipe.Request{} = request, client) do
    Conn.new()
    |> Map.put(:request, request)
    |> request(client)
  end

  def request(%HTTPipe.Conn{} = conn, client) do
    conn = apply_transformations(conn, client)

    case Conn.execute(conn) do
      {:ok, conn} ->
        body = parse_body(conn.response)
        resp = Map.put(conn.response, :body, body)
        conn = Map.put(conn, :response, resp)

        if resp.status_code >= 100 and resp.status_code < 400 do
          {:ok, conn}
        else
          {:error, conn}
        end

      {:error, conn} ->
        {:error, conn}
    end
  end

  # private

  defp parse_body(resp) do
    Jason.decode!(resp.body)
  rescue
    _ -> resp.body
  end

  @doc false
  def apply_transformations(conn, nil), do: conn

  def apply_transformations(conn, client) do
    conn =
      case :url in Map.get(conn, :completed_transformations, []) do
        false ->
          Url.apply(conn, client)

        true ->
          conn
      end

    conn =
      case :body in Map.get(conn, :completed_transformations, []) do
        false ->
          Body.apply(conn, "")

        true ->
          conn
      end

    conn =
      case :hackney_options in Map.get(conn, :completed_transformations, []) do
        false ->
          HackneyOptions.apply(conn, client)

        true ->
          conn
      end

    case :auth in Map.get(conn, :completed_transformations, []) do
      false ->
        Auth.apply(conn, client)

      true ->
        conn
    end
  end
end

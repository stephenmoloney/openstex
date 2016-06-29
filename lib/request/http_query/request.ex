defimpl Openstex.Request, for: Openstex.HttpQuery  do
  @moduledoc :false
  alias Openstex.{HttpQuery, Response}

  @spec request(HttpQuery.t, Keyword.t, atom) :: {:ok, Response.t} | {:error, Response.t}
  def request(%HttpQuery{} = q, httpoison_opts, _client) do
    options = Keyword.merge(q.options, httpoison_opts)
    case HTTPoison.request(q.method, q.uri, q.body, q.headers, options) do
      {:ok, resp} ->
        body = parse_body(resp)
        resp = %Response{ body: body, headers: resp.headers |> Enum.into(%{}), status_code: resp.status_code }
        if resp.status_code >= 100 and resp.status_code < 400 do
          {:ok, resp}
        else
          {:error, resp}
        end
      {:error, resp} ->
        {:error, %HTTPoison.Error{reason: resp.reason}}
    end
  end


  # private


  def parse_body(resp) do
    try do
       resp.body |> Poison.decode!()
    rescue
      _ ->
        resp.body
    end
  end


end

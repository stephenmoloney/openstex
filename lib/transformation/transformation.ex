defimpl Openstex.Transformation, for: Any do
  @moduledoc :false
  alias Openstex.Query
  @default_headers [{"Content-Type", "application/json; charset=utf-8"}]


  # Public


  @spec prepare_request(Query.t, Keyword.t, atom) :: Openstex.HttpQuery.t
  def prepare_request(query, httpoison_opts, client)

  def prepare_request(%Query{method: method, uri: uri, headers: headers, params: params}, httpoison_opts, client) do
    uri = client.swift().get_endpoint() <> uri
    uri =
    cond do
      params == %{} -> uri
      Map.get(params, :query_string, :nil) != :nil -> uri <> "?" <> (Map.fetch!(params, :query_string) |> URI.encode_query())
      :true -> uri
    end
    body = if Map.has_key?(params, :binary), do: Map.get(params, :binary), else: ""
    headers =  headers(client, headers)
    default_httpoison_opts = client.config().httpoison_config(client)
    options = Keyword.merge(default_httpoison_opts, httpoison_opts)
    %Openstex.HttpQuery{method: method, uri: uri, body: body, headers: headers, options: options, service: :openstack}
  end


  # Private


  defp headers(client, headers) do
    @default_headers ++
    [
      {
        "X-Auth-Token", client.swift().get_xauth_token()
      }
    ] ++
    headers
    |> Enum.uniq()
  end


end

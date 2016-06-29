defprotocol Openstex.Transformation do
  @moduledoc :false
  @fallback_to_any true

  @spec prepare_request(Openstex.Query.t,  Keyword.t, atom) :: Openstex.HttpQuery.t
  def prepare_request(queryable, httpoison_opts, client)

end

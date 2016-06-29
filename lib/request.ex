defprotocol Openstex.Request do
  @moduledoc false
  @fallback_to_any true

  @spec request(Openstex.Query.t, Keyword.t, atom) :: Openstex.HttpQuery.t
  def request(query, httpoison_opts, client)

end

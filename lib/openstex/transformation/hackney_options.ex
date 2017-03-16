defmodule Openstex.Transformation.HackneyOptions do
  @moduledoc :false


  # Public

  @spec apply(HTTPipe.Conn.t, atom) :: HTTPipe.Conn.t
  def apply(%HTTPipe.Conn{request: %HTTPipe.Request{}} = conn, client) do
    trans = Map.get(conn, :completed_transformations, [])
    default_hackney_opts = client.config().hackney_config(client)
    hackney_options = Map.get(conn, :adapter_options, [])
    options = merge_options(default_hackney_opts, hackney_options)
    Map.put(conn, :adapter_options, options)
    |> Map.put(:completed_transformations, trans ++ [:hackney_options])
  end


  # Private

  defp merge_options(opts1, opts2) do
    opts1 = Enum.into(opts1, %{})
    opts2 = Enum.into(opts2, %{})
    opts = Map.merge(opts1, opts2)
    Enum.into(opts, [])
  end

end

defmodule Openstex.Adapter.Keystone do
  @moduledoc ~s"""
  A behaviour adapter module to be implemented by clients that using the `Openstex` library
  for handling Keystone Authentication.
  """
  alias Openstex.Services.Keystone.V2.Helpers.Identity

  @callback start_link(client :: atom) :: {:ok, pid} | {:error, :already_started}
  @callback start_link(client :: atom, opts :: Keyword.t) :: {:ok, pid} | {:error, :already_started}
  @callback identity(client :: atom) :: Identity.t | no_return
  @callback get_xauth_token(client :: atom) :: String.t | no_return

end

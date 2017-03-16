defmodule Openstex.Adapter.Keystone do
  @moduledoc ~s"""
  A behaviour adapter module to be implemented by clients that using the `Openstex` library
  for handling Keystone Authentication.
  """
  alias Openstex.Keystone.V2.Helpers.Identity

  @callback start_link(atom) :: {:ok, pid} | {:error, :already_started}
  @callback start_link(atom, opts :: Keyword.t) :: {:ok, pid} | {:error, :already_started}
  @callback identity(atom) :: Identity.t | no_return
  @callback get_xauth_token(atom) :: String.t | no_return

end

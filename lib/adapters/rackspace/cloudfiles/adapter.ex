defmodule Openstex.Adapters.Rackspace.Cloudfiles.Adapter do
  @moduledoc :false
  @behaviour Openstex.Adapter

  def config(), do: Openstex.Adapters.Rackspace.Cloudfiles.Config
  def keystone(), do: Openstex.Adapters.Rackspace.Cloudfiles.Keystone

end


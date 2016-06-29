defmodule Openstex.Adapters.Rackspace.CloudfilesCDN.Adapter do
  @moduledoc :false
  @behaviour Openstex.Adapter

  def config(), do: Openstex.Adapters.Rackspace.CloudfilesCDN.Config
  def keystone(), do: Openstex.Adapters.Rackspace.CloudfilesCDN.Keystone

end


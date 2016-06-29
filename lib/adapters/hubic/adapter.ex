defmodule Openstex.Adapters.Hubic.Adapter do
  @moduledoc :false
  @behaviour Openstex.Adapter

  def config(), do: Openstex.Adapters.Hubic.Config
  def keystone(), do: Openstex.Adapters.Hubic.Keystone

end


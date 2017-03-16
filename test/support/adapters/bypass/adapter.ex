defmodule Openstex.Adapters.Bypass do
  @moduledoc :false
  @behaviour Openstex.Adapter

  def config(), do: Openstex.Adapters.Bypass.Config
  def keystone(), do: Openstex.Adapters.Bypass.Keystone

end


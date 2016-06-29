defmodule Openstex.Adapters.Ovh.Webstorage.Adapter do
  @moduledoc :false
  @behaviour Openstex.Adapter

  def config(), do: Openstex.Adapters.Ovh.Webstorage.Config
  def keystone(), do: Openstex.Adapters.Ovh.Webstorage.Keystone

end


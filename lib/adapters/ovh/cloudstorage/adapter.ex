defmodule Openstex.Adapters.Ovh.Cloudstorage.Adapter do
  @moduledoc :false
  @behaviour Openstex.Adapter

  def config(), do: Openstex.Adapters.Ovh.Cloudstorage.Config
  def keystone(), do: Openstex.Adapters.Ovh.Cloudstorage.Keystone

end


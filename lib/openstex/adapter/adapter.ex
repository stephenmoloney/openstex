defmodule Openstex.Adapter do
  @moduledoc :false
  @callback keystone() :: atom
  @callback config() :: atom
end
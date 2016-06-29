defmodule Openstex.Supervisor do
  @moduledoc :false
  use Supervisor

  #  Public

  def start_link(client, opts \\ []) do
    Og.context(__ENV__, :debug)
    Supervisor.start_link(__MODULE__, {client, opts}, name: supervisor_name(client))
  end

  #  Callbacks

  def init({client, opts}) do
    Og.context(__ENV__, :debug)
    config = client.config()
    sup_tree =
    if config.__info__(:module) != :nil do
      [{client, {config, :start_agent, [client, opts]}, :permanent, 10_000, :worker, [config]}]
    else
      []
    end
    supervise(sup_tree, strategy: :one_for_one, max_restarts: 30)
  end

  defp supervisor_name(client) do
    Module.concat(Openstex.Supervisor, client)
  end

end

defmodule Openstex.Supervisor do
  @moduledoc false
  use Supervisor

  #  Public

  def start_link(client, opts \\ []) do
    Supervisor.start_link(__MODULE__, {client, opts}, name: supervisor_name(client))
  end

  #  Callbacks

  def init({client, opts}) do
    config = client.config()
    keystone = client.keystone()

    sup_tree =
      if config.__info__(:module) != nil do
        [{config, {config, :start_agent, [client, opts]}, :permanent, 10_000, :worker, [config]}]
      else
        []
      end

    sup_tree =
      if keystone.__info__(:module) != nil do
        sup_tree ++
          [{client, {keystone, :start_link, [client]}, :permanent, 20_000, :worker, [keystone]}]
      else
        []
      end

    # max 10 restarts in 1 minute
    supervise(sup_tree, strategy: :one_for_one, max_restarts: 3, max_seconds: 60)
  end

  defp supervisor_name(client) do
    Module.concat(Openstex.Supervisor, client)
  end
end

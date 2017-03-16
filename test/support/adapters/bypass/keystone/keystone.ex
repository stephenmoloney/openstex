defmodule Openstex.Adapters.Bypass.Keystone do
  @moduledoc :false
  alias Openstex.Adapters.Bypass.Keystone.Utils
  import Openstex.Utils, only: [ets_tablename: 1]
  @behaviour Openstex.Adapter.Keystone
  @get_identity_retries 5
  @get_identity_interval 1000


  # Public Openstex.Adapter.Keystone callbacks

  def start_link(openstex_client) do
    GenServer.start_link(__MODULE__, openstex_client, [name: openstex_client])
  end

  def start_link(openstex_client, _opts) do
    start_link(openstex_client)
  end

  def identity(openstex_client) do
    get_identity(openstex_client)
  end

  def get_xauth_token(openstex_client) do
    get_identity(openstex_client) |> Map.get(:token) |> Map.get(:id)
  end

  # Genserver Callbacks

  def init(openstex_client) do
    :erlang.process_flag(:trap_exit, :true)
    create_ets_table(openstex_client)
    identity = Utils.create_identity(openstex_client)
    identity = Map.put(identity, :lock, :false)
    :ets.insert(ets_tablename(openstex_client), {:identity, identity})
    timer_ref = Process.send_after(self(), :update_identity, get_seconds_to_expiry(identity))
    {:ok, {openstex_client, identity, timer_ref}}
  end


  def handle_call(:add_lock, _from, {openstex_client, identity, timer_ref}) do
    new_identity = Map.put(identity, :lock, :true)
    :ets.insert(ets_tablename(openstex_client), {:identity, new_identity})
    {:reply, :ok, {openstex_client, identity, timer_ref}}
  end
  def handle_call(:update_identity, _from, {openstex_client, identity, timer_ref}) do
    {:reply, :ok, _identity} = GenServer.call(self(), :add_lock)
    {:ok, new_identity} = Utils.create_identity(openstex_client) |> Map.put(:lock, :false)
    :ets.insert(ets_tablename(openstex_client), {:identity, new_identity})
    :timer.cancel(timer_ref)
    timer_ref = Process.send_after(self(), :update_identity, get_seconds_to_expiry(new_identity))
    {:reply, :ok, {openstex_client, identity, timer_ref}}
  end
  def handle_call(:stop, _from, state) do
    {:stop, :shutdown, :ok, state}
  end


  def handle_info(:update_identity, _from, _state) do
    {:reply, :ok, _identity} = GenServer.call(self(), :update_identity)
  end
  def handle_info(_, state), do: {:ok, state}




  def terminate(_reason, {openstex_client, _identity, _timer_ref}) do
    :ets.delete(ets_tablename(openstex_client))
    :ok
  end

  # private


  defp get_identity(openstex_client) do
    unless supervisor_exists?(openstex_client), do: start_link(openstex_client)
    get_identity(openstex_client, 0)
  end
  defp get_identity(openstex_client, index) do
    retry = fn(openstex_client, index) ->
      if index > @get_identity_retries do
        raise "Cannot retrieve openstack identity, #{__ENV__.module}, #{__ENV__.line}, client: #{openstex_client}"
      else
        :timer.sleep(@get_identity_interval)
        get_identity(openstex_client, index + 1)
      end
    end

    if ets_tablename(openstex_client) in :ets.all() do
      table = :ets.lookup(ets_tablename(openstex_client), :identity)
      case table do
        [identity: identity] ->
          if identity.lock == :true do
            retry.(openstex_client, index)
          else
            identity
          end
        [] -> retry.(openstex_client, index)
      end
    else
      retry.(openstex_client, index)
    end
  end


  defp get_seconds_to_expiry(identity) do
    iso_time = identity.token.expires
    (
    DateTime.from_iso8601(iso_time)
    |> Tuple.to_list()
    |> Enum.at(1)
    |> DateTime.to_unix()
    ) -
    (DateTime.utc_now() |> DateTime.to_unix())
  end


  defp create_ets_table(openstex_client) do
    ets_options = [
                   :set, # type
                   :protected, # read - all, write this process only.
                   :named_table,
                   {:heir, :none}, # don't let any process inherit the table. when the ets table dies, it dies.
                   {:write_concurrency, :false},
                   {:read_concurrency, :true}
                  ]
    unless ets_tablename(openstex_client) in :ets.all() do
      :ets.new(ets_tablename(openstex_client), ets_options)
    end
  end


  defp supervisor_exists?(client) do
    Process.whereis(client) != :nil
  end


end

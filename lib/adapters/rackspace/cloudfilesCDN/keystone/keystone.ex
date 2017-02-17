defmodule Openstex.Adapters.Rackspace.CloudfilesCDN.Keystone do
  @moduledoc :false
  alias Openstex.Services.Keystone.V2.Helpers.Identity
  alias Openstex.Adapters.Rackspace.CloudfilesCDN.Keystone.Utils
  import Openstex.Utils, only: [ets_tablename: 1]
  @behaviour Openstex.Adapter.Keystone
  @get_identity_retries 5
  @get_identity_interval 1000


  # Public Openstex.Adapter.Keystone callbacks

  def start_link(openstex_client) do
    Og.context(__ENV__, :debug)
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
    Og.context(__ENV__, :debug)
    :erlang.process_flag(:trap_exit, :true)
    create_ets_table(openstex_client)
    identity = create_identity(openstex_client)
    identity = Map.put(identity, :lock, :false)
    :ets.insert(ets_tablename(openstex_client), {:identity, identity})
    expiry = to_seconds(identity)
    Task.start_link(fn -> monitor_expiry(expiry) end)
    {:ok, {openstex_client, identity}}
  end

  def handle_call(:add_lock, _from, {openstex_client, identity}) do
    Og.context(__ENV__, :debug)
    new_identity = Map.put(identity, :lock, :true)
    :ets.insert(ets_tablename(openstex_client), {:identity, new_identity})
    {:reply, :ok, {openstex_client, new_identity}}
  end

  def handle_call(:remove_lock, _from, {openstex_client, identity}) do
    Og.context(__ENV__, :debug)
    new_identity = Map.put(identity, :lock, :false)
    :ets.insert(ets_tablename(openstex_client), {:identity, new_identity})
    {:reply, :ok, {openstex_client, new_identity}}
  end

  def handle_call(:update_identity, _from, {openstex_client, _identity}) do
    Og.context(__ENV__, :debug)
    {:ok, new_identity} = Utils.create_identity(openstex_client) |> Map.put(:lock, :false)
    :ets.insert(ets_tablename(openstex_client), {:identity, new_identity})
    {:reply, :ok, {openstex_client, new_identity}}
  end

  def handle_call(:stop, _from, state) do
    Og.context(__ENV__, :debug)
    {:stop, :shutdown, :ok, state}
  end

  def terminate(:shutdown, {openstex_client, _identity}) do
    Og.context(__ENV__, :debug)
    :ets.delete(ets_tablename(openstex_client)) # explicilty remove
    :ok
  end

  def terminate(:normal, {_openstex_client, _identity}) do
    Og.context(__ENV__, :debug)
    :ok
  end

  # private

  @spec create_identity(atom) :: Identity.t | no_return
  defp create_identity(openstex_client) do
    Og.context(__ENV__, :debug)
    Utils.create_identity(openstex_client)
  end


  defp get_identity(openstex_client) do
    unless supervisor_exists?(openstex_client), do: start_link(openstex_client)
    get_identity(openstex_client, 0)
  end
  defp get_identity(openstex_client, index) do
    Og.context(__ENV__, :debug)

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


  defp monitor_expiry(expires) do
    Og.context(__ENV__, :debug)
    interval = (expires - 30) * 1000
    :timer.sleep(interval)
    {:reply, :ok, _identity} = GenServer.call(self(), :add_lock)
    {:reply, :ok, _identity} = GenServer.call(self(), :update_identity)
    {:reply, :ok, new_identity} = GenServer.call(self(), :remove_lock)
    expires = to_seconds(new_identity.token.expires)
    monitor_expiry(expires)
  end


  defp create_ets_table(openstex_client) do
    Og.context(__ENV__, :debug)
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


  defp to_seconds(identity) do
    iso_time = identity.token.expires
    {:ok, expiry_ndt, offset} = Calendar.NaiveDateTime.Parse.iso8601(iso_time)
    offset =
    case offset do
      :nil -> 0
      offset -> offset
    end
    {:ok, expiry_dt_utc} = Calendar.NaiveDateTime.with_offset_to_datetime_utc(expiry_ndt, offset)
    {:ok, now} = Calendar.DateTime.from_erl(:calendar.universal_time(), "UTC")
    {:ok, seconds, _microseconds, _when} = Calendar.DateTime.diff(expiry_dt_utc, now)
    if seconds > 0 do
      seconds
    else
      0
    end
  end


  defp supervisor_exists?(client) do
    Process.whereis(client) != :nil
  end


end

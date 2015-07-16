defmodule KV.Registry do
  use GenServer
  require Logger

  ### Client API

  def start_link(table, event_manager, buckets,  opts \\ []) do
    Logger.debug("KV.Registry.start_link")
    GenServer.start_link(__MODULE__, {table, event_manager, buckets}, opts)
  end

  def lookup(table, name) do
    Logger.debug("KV.Registry.lookup #{name}")
    case :ets.lookup(table, name) do
      [{^name, bucket}] -> {:ok, bucket}
      [] -> :error
    end
  end

  def create(server, name) do
    Logger.debug("KV.Registry.create #{name}")
    GenServer.call(server, {:create, name})
  end

  def stop(server) do
    Logger.debug("KV.Registry.stop")
    GenServer.call(server, :stop)
  end

  ### Server API

  def init({table, events, buckets}) do
    refs = :ets.foldl(fn {name, pid}, acc ->
      Map.put(acc, Process.monitor(pid), name)
    end, %{}, table)

    {:ok, %{names: table, refs: refs, events: events, buckets: buckets}}
  end

  #def handle_call({:lookup, name}, _from, state) do
    #{:reply, Map.fetch(state.names, name), state}
  #end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_call({:create, name}, _from, state) do
    case lookup(state.names, name) do
      {:ok, _pid} ->
        {:noreply, state}
      :error ->
        {:ok, pid} = KV.Bucket.Supervisor.start_bucket(state.buckets)
        ref = Process.monitor(pid)
        refs = Map.put(state.refs, ref, name)
        :ets.insert(state.names, {name, pid})
        GenEvent.sync_notify(state.events, {:create, name, pid})
        {:reply, pid, %{state | refs: refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    {name, refs} = Map.pop(state.refs, ref)
    :ets.delete(state.names, name)
    GenEvent.sync_notify(state.events, {:exit, name, pid})
    {:noreply, %{state | refs: refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

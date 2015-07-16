defmodule KV.Bucket do
  require Logger

  def start_link do
    Logger.debug("KV.Bucket.start_link")
    Agent.start_link(fn -> %{} end)
  end

  def get(bucket, key) do
    Logger.debug("KV.Bucket.get #{key}")
    Agent.get(bucket, &Map.get(&1, key))
  end

  def put(bucket, key, value) do
    Logger.debug("KV.Bucket.put #{key}")
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  def delete(bucket, key) do
    Logger.debug("KV.Bucket.delete")
    Agent.get_and_update(bucket, &Map.pop(&1, key))
  end
end

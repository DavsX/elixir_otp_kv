defmodule KV.Bucket.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Logger.debug("KV.Bucket.Supervisor.start_link")
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_bucket(supervisor) do
    Logger.debug("KV.Bucket.Supervisor.start_bucket")
    Supervisor.start_child(supervisor, [])
  end

  def init(:ok) do
    Logger.debug("KV.Bucket.Supervisor.init :ok")

    children = [
      worker(KV.Bucket, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end

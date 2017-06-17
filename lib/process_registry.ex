defmodule HunterGatherer.ProcessRegistry do
  alias HunterGatherer.UrlProcessor

  def start_link do
    Agent.start_link(fn -> MapSet.new end, name: __MODULE__)
  end

  def start_enough_processes(backpack, max_processes) do
    num_of_pending = length(backpack.pending) # TODO: move to Backpack, leaking implementation
    processes_to_start = Enum.min([num_of_pending, max_processes]) - count()
    if processes_to_start > 0 do
      {url, backpack} = Backpack.get_next_pending(backpack)
      IO.puts url

      UrlProcessor.process_async(self(), url, backpack)
      |> add_process

      start_enough_processes(backpack, max_processes)
    else
      backpack
    end
  end

  def add_process(pid) do
    Agent.update(__MODULE__, &MapSet.put(&1, pid))
  end

  def remove_process(pid) do
    Agent.update(__MODULE__, &MapSet.delete(&1, pid))
  end

  def has_active_processes? do
    count() > 0
  end

  def count do
    Agent.get(__MODULE__, &MapSet.size(&1))
  end
end

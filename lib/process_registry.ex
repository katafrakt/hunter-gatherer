defmodule HunterGatherer.ProcessRegistry do
  alias HunterGatherer.UrlProcessor

  def start_link do
    Agent.start_link(fn -> MapSet.new end, name: __MODULE__)
  end

  def start_enough_processes(backpack, max_processes) do
    remove_dead()
    num_of_pending = Backpack.num_of_pending(backpack)
    processes_to_start = Enum.min([num_of_pending, max_processes]) - count()
    if processes_to_start > 0 do
      {url, backpack} = Backpack.get_next_pending(backpack)

      # not sure why double-check is needed here, but it is
      if !Backpack.has_been_processed?(backpack, url) do
        UrlProcessor.process_async(self(), url)
        |> add_process
      end

      start_enough_processes(backpack, max_processes)
    else
      backpack
    end
  end

  def remove_dead do
    Agent.update(__MODULE__, fn(set) ->
      set
      |> MapSet.to_list
      |> Enum.filter(&Process.alive?(&1))
      |> MapSet.new
    end)
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

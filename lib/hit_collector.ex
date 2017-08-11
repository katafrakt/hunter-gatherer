defmodule HunterGatherer.HitCollector do
  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  def collect(url) do
    Agent.update(__MODULE__, fn(set) ->
      case set[url] do
        nil ->
          Map.put(set, url, 1)
        old_value ->
          Map.put(set, url, old_value + 1)
      end
    end)
  end

  def get(url) do
    IO.puts url
    case Agent.get(__MODULE__, &(&1[url])) do
      nil -> 0
      num -> num
    end
  end

  def add_many(urls) do
    Enum.each(urls, &collect(&1))
  end
end

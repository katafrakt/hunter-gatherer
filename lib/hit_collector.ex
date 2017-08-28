defmodule HunterGatherer.HitCollector do
  alias HunterGatherer.Utils

  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  def collect(url, source) do
    Agent.update(__MODULE__, fn(set) ->
      case set[url] do
        nil ->
          Map.put(set, url, %{ count: 1, source: [source] })
        old_value ->
          Map.put(set, url, %{ count: old_value.count + 1, source: [source | old_value.source] })
      end
    end)
  end

  def get(url) do
    case Agent.get(__MODULE__, &(&1[url])) do
      nil -> 0
      num -> num
    end
  end

  def add_many(urls, source) do
    urls
    |> Enum.map(&Utils.normalize_url(&1))
    |> Enum.each(&collect(&1, source))
  end
end

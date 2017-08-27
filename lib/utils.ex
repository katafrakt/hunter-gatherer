defmodule HunterGatherer.Utils do
  def normalize_url(url) do
    url = struct(URI.parse(url), fragment: nil) |> to_string
    Regex.replace(~r/ /, url, "%20")
  end

  def is_internal?(url) do
    base = config_get(:base)
    case String.split(url, base |> to_string, parts: 2) do
      [_,_] -> true
      _ -> false
    end
  end

  def init_config do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  def config_put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  def config_get(key) do
    Agent.get(__MODULE__, &(&1[key]))
  end
end

defmodule HunterGatherer.Config do
  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  def get(key) do
    Agent.get(__MODULE__, &(&1[key]))
  end

  def set(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  def setup(url, opts) do
    set(:output_file, Keyword.get(opts, :output, "report.html"))
    set(:base, URI.parse(url))
    set(:user_agent, "Mozilla/5.0 (X11; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0")
  end
end

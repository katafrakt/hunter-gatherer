defmodule HunterGatherer do
  alias HunterGatherer.Reporters
  alias HunterGatherer.ProcessRegistry
  alias HunterGatherer.HitCollector
  alias HunterGatherer.Config

  def start(url) do
    initialize()
    backpack = Backpack.init(url)
    Config.set(:base, URI.parse(url))
    loop(backpack)
  end

  defp loop(backpack) do
    if Backpack.has_next_pending?(backpack) || ProcessRegistry.has_active_processes? do
      ProcessRegistry.start_enough_processes(backpack, 5)
      |> listen
      |> loop
    else
      Reporters.Html.generate_report(backpack)
    end
  end

  defp listen(backpack) do
    receive do
      {:ok, url, links} ->
        HitCollector.add_many(links, url)
        backpack
        |> Backpack.append_pending(links)
        |> Backpack.append_good(url)
      {:error, url, reason} ->
        backpack
        |> Backpack.append_bad(url, reason)
      after
        1_000 ->
          IO.puts "Oooops, timeout!"
          IO.puts ProcessRegistry.count()
          backpack
    end
  end

  defp initialize do
    ProcessRegistry.start_link()
    HitCollector.start_link()
    Config.start_link()
  end
end

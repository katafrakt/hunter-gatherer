defmodule HunterGatherer do
  alias HunterGatherer.Reporter
  alias HunterGatherer.ProcessRegistry
  alias HunterGatherer.HitCollector
  alias HunterGatherer.Utils

  def start(url) do
    initialize()
    backpack = Backpack.init(url)
    Utils.config_put(:base, URI.parse(url))
    loop(backpack)
  end

  defp loop(backpack) do
    if Backpack.has_next_pending?(backpack) || ProcessRegistry.has_active_processes? do
      ProcessRegistry.start_enough_processes(backpack, 5)
      |> listen
      |> loop
    else
      Reporter.generate_html_report(backpack)
    end
  end

  defp listen(backpack) do
    receive do
      {:ok, url, links} ->
        HitCollector.add_many(links)
        backpack
        |> Backpack.append_pending(links)
        |> Backpack.append_good(url)
      {:error, url, reason} ->
        backpack
        |> Backpack.append_bad(url, reason)
    end
  end

  defp initialize do
    ProcessRegistry.start_link()
    HitCollector.start_link()
    Utils.init_config()
  end
end

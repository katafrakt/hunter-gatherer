defmodule HunterGatherer do
  alias HunterGatherer.Reporter
  alias HunterGatherer.ProcessRegistry

  def start(url) do
    backpack = Backpack.init(url)
    ProcessRegistry.start_link()
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
        backpack
        |> Backpack.append_pending(links)
        |> Backpack.append_good(url)
      {:error, url, reason} ->
        backpack
        |> Backpack.append_bad(url, reason)
    end
  end
end

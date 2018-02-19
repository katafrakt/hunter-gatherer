defmodule HunterGatherer do
  alias HunterGatherer.Reporters
  alias HunterGatherer.ProcessRegistry
  alias HunterGatherer.HitCollector
  alias HunterGatherer.Config

  def start(url) do
    initialize()
    backpack = Backpack.init(url)
    Config.set(:base, URI.parse(url))
    Config.set(:user_agent, "Mozilla/5.0 (X11; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0")
    IO.write "Starting..."
    loop(backpack)
  end

  defp loop(backpack) do
    if Backpack.has_next_pending?(backpack) || ProcessRegistry.has_active_processes? do
      ProcessRegistry.start_enough_processes(backpack, 5)
      |> listen
      |> print_debug
      |> loop
    else
      IO.puts("")
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

  defp print_debug(backpack) do
    IO.write("\r")
    processed = Backpack.num_of_processed(backpack)
    queued = Backpack.num_of_pending(backpack)
    IO.write("Processed: #{processed}, queued: #{queued}        ")
    backpack
  end
end

defmodule HunterGatherer do
  alias HunterGatherer.Reporter

  def start(url) do
    backpack = Backpack.init(url)
    loop(backpack, 5)
  end

  defp loop(backpack, processes_to_start \\ 1) do
    if Backpack.has_next_pending?(backpack) do
      {url, backpack} = Backpack.get_next_pending(backpack)

      if Backpack.has_been_processed?(backpack, url) do
        loop(backpack)
      else
        for _ <- 1..processes_to_start do
          process_async(self(), url, backpack)
        end

        receive do
          {:ok, url, links} ->
            backpack
            |> Backpack.append_pending(links)
            |> Backpack.append_good(url)
            |> loop
          {:error, url, reason} ->
            backpack
            |> Backpack.append_bad(url, reason)
            |> loop
        end
      end
    else
      Reporter.generate_html_report(backpack)
    end
  end

  defp process_async(pid, url, backpack) do
    spawn fn ->
      result = process_url(url, backpack)
      send(pid, result)
    end
  end

  defp process_url(url, backpack) do
    IO.puts url
    case HTTPoison.get(url, [], [follow_redirect: true, max_redirect: 5, ssl: [{:versions, [:'tlsv1.2']}]]) do
      {:ok, %{status_code: 200} = result} ->
        {:ok, url, get_links(url, result, backpack)}
      {:ok, result} ->
        {:error, url, result.status_code}
      {:error, error} ->
        {:error, url, error}
    end
  end

  defp get_links(url, result, backpack) do
    case String.split(url, backpack.base |> to_string, parts: 2) do
      [_, _] ->
        result.body
        |> Floki.find("a")
        |> Floki.attribute("href")
        |> Enum.map(fn(url) -> URI.parse(url) end)
        |> Enum.map(fn(url) -> URI.merge(backpack.base, url) |> to_string end)
      [_] ->
        []
    end
  end
end

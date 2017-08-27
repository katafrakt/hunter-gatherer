defmodule HunterGatherer.UrlProcessor do
  alias HunterGatherer.ProcessRegistry
  alias HunterGatherer.Utils

  def process_async(pid, url, backpack) do
    spawn fn ->
      result = process_url(url, backpack)
      send(pid, result)
      ProcessRegistry.remove_process(self())
    end
  end

  defp process_url(url, backpack) do
#    IO.puts url
    case HTTPoison.get(url, [], [follow_redirect: true, max_redirect: 5, ssl: [{:versions, [:'tlsv1.2']}]]) do
      {:ok, %{status_code: 200} = result} ->
        {:ok, url, get_links(url, result, backpack)}
      {:ok, result} ->
        {:error, url, result.status_code}
      {:error, error} ->
        {:error, url, error}
    end
  end

  defp get_links(original_url, result, backpack) do
    if Utils.is_internal?(original_url) do
      original_uri = URI.parse(original_url)
      result.body
      |> Floki.find("a")
      |> Floki.attribute("href")
      |> Enum.map(fn(url) -> URI.parse(url) end)
      |> Enum.map(fn(url) -> URI.merge(Utils.config_get(:base), URI.merge(original_uri, url)) |> to_string end)
    else
      []
    end
  end
end

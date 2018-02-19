defmodule HunterGatherer.UrlProcessor do
  alias HunterGatherer.ProcessRegistry
  alias HunterGatherer.Utils
  alias HunterGatherer.Config

  def process_async(pid, url) do
    spawn fn ->
      result = process_url(url)
      send(pid, result)
      ProcessRegistry.remove_process(self())
    end
  end

  defp process_url(url) do
    case HTTPoison.get(url, [{"User-Agent", Config.get(:user_agent)}], [follow_redirect: true, max_redirect: 5, ssl: [{:versions, [:'tlsv1.2']}]]) do
      {:ok, %{status_code: 200} = result} ->
        {:ok, url, get_links(url, result)}
      {:ok, result} ->
        {:error, url, result.status_code}
      {:error, error} ->
        {:error, url, error}
    end
  end

  defp get_links(original_url, result) do
    if Utils.is_internal?(original_url) do
      original_uri = URI.parse(original_url)
      result.body
      |> Floki.find("a")
      |> Floki.attribute("href")
      |> Enum.map(fn(url) -> URI.parse(url) end)
      |> Enum.map(fn(url) -> URI.merge(Config.get(:base), URI.merge(original_uri, url)) |> to_string end)
    else
      []
    end
  end
end

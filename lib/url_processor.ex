defmodule HunterGatherer.UrlProcessor do
  @moduledoc false

  alias HunterGatherer.ProcessRegistry
  alias HunterGatherer.Utils
  alias HunterGatherer.Config

  def process_async(pid, url) do
    spawn(fn ->
      result = process_url(url)
      send(pid, result)
      ProcessRegistry.remove_process(self())
    end)
  end

  defp process_url(url) do
    case Req.get(url,
           headers: [{"User-Agent", Config.get(:user_agent)}],
           redirect: true,
           max_redirects: 8,
           connect_options: [transport_opts: [versions: [:"tlsv1.2"], timeout: 30_000]],
           receive_timeout: 45_000
         ) do
      {:ok, %{status: 200} = result} ->
        {:ok, url, get_links(url, result)}

      {:ok, result} ->
        {:error, url, result.status}

      {:error, error} ->
        {:error, url, error}
    end
  end

  defp get_links(original_url, result) do
    if Utils.is_internal?(original_url) do
      original_uri = URI.parse(original_url)

      {:ok, document} = Floki.parse_document(result.body)

      document
      |> Floki.find("a")
      |> Floki.attribute("href")
      |> Enum.map(fn url -> URI.parse(url) end)
      |> Enum.map(fn url ->
        URI.merge(Config.get(:base), URI.merge(original_uri, url)) |> to_string
      end)
    else
      []
    end
  end
end

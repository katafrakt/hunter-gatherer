defmodule LinkExtractor do
  @moduledoc "Extracts links from HTML document"

  def call(html, config, original_uri) do
    {:ok, document} = Floki.parse_document(html)

    document
    |> Floki.find("a")
    |> Floki.attribute("href")
    |> Enum.map(fn url -> URI.parse(url) end)
    |> Enum.map(fn url ->
      URI.merge(config.base, URI.merge(original_uri, url)) |> to_string
    end)
  end
end

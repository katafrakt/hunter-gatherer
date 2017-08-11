defmodule HunterGatherer.Utils do
  def normalize_url(url) do
    url = struct(URI.parse(url), fragment: nil) |> to_string
    Regex.replace(~r/ /, url, "%20")
  end
end

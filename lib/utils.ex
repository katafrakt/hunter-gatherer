defmodule HunterGatherer.Utils do
  alias HunterGatherer.Config

  def normalize_url(url) do
    url = struct(URI.parse(url), fragment: nil) |> to_string
    Regex.replace(~r/ /, url, "%20")
  end

  def is_internal?(url) do
    base = Config.get(:base)
    case String.split(url, base |> to_string, parts: 2) do
      [_,_] -> true
      _ -> false
    end
  end
end

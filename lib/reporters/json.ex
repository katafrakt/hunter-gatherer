defmodule HunterGatherer.Reporters.Json do
  @moduledoc false
  
  alias HunterGatherer.HitCollector
  alias HunterGatherer.Config

  import HunterGatherer.Reporters.Common, only: [format_error: 1]

  def generate_report(backpack) do
    filename = Config.get(:output_file)
    {:ok, file} = File.open(filename, [:write])

    data =
      backpack.bad
      |> Enum.map(fn {url, reason} ->
        hits_data = HitCollector.get(url)

        %{
          url: url,
          reason: format_error(reason),
          hits: hits_data.count,
          sources: hits_data.source
        }
      end)
      |> Enum.sort(&(&1.hits >= &2.hits))

    json = Poison.encode!(data)
    IO.binwrite(file, json)
  end
end

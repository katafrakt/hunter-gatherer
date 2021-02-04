defmodule HunterGatherer.CLI do
  @moduledoc false
  
  def main(args) do
    {opts, [url], _} =
      OptionParser.parse(args,
        switches: [
          output: :string,
          format: :string
        ],
        aliases: [
          o: :output,
          f: :format
        ]
      )

    HunterGatherer.start(url, opts)
  end
end

defmodule HunterGatherer.CLI do
  def main(args) do
    {opts, [url], _} = OptionParser.parse(args,
      switches: [
        output: :string
      ],
      aliases: [
        o: :output
      ]
    )
    HunterGatherer.start(url, opts)
  end
end

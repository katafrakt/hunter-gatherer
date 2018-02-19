defmodule HunterGatherer.CLI do
  def main(args) do
    {opts, [url], _} = OptionParser.parse(args)
    HunterGatherer.start(url)
  end
end

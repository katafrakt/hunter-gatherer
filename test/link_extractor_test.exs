defmodule LinkExtractorTest do
  use ExUnit.Case, async: true
  doctest LinkExtractor

  describe "call/2" do
    test "simple html" do
      doc = """
      <html>
      <body>
      <a href="https://google.com">google</a>
      <a href="http://internal.site/about">about</a>
      <a href="/home">about</a>
      </body>
      </html>
      """

      base = "http://internal.site"

      assert LinkExtractor.call(doc, build_config(base), base) == [
               "https://google.com",
               "http://internal.site/about",
               "http://internal.site/home"
             ]
    end
  end

  defp build_config(base) do
    HunterGatherer.Config.new(base)
  end
end

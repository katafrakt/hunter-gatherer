defmodule ConfigTest do
  use ExUnit.Case
  doctest HunterGatherer.Config
  alias HunterGatherer.Config

  @url "https://github.com"

  setup do
    Config.start_link()
    :ok
  end

  describe "setup" do
    test "sets defaults" do
      Config.setup(@url, [])
      assert(Config.get(:base) == URI.parse(@url))
      assert(Config.get(:format) == "html")
      assert(Config.get(:user_agent) =~ "Mozilla")
    end

    test "overwrites defaults" do
      Config.setup(@url, [user_agent: "HG", format: "json"])
      assert(Config.get(:format) == "json")
      assert(Config.get(:user_agent) == "HG")
    end

    test "does not overwrite base" do
      Config.setup(@url, [base: "HG", format: "json"])
      assert(Config.get(:base) == URI.parse(@url))
    end

    test "generates default output name" do
      Config.setup(@url, [format: "png"])
      assert(Config.get(:output_file) == "report.png")
    end
  end

  describe "set" do
    test "sets value" do
      Config.setup(@url, [])
      Config.set(:foo, "bar")
      assert(Config.get(:foo) == "bar")
    end
  end
end

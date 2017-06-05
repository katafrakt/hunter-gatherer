defmodule HunterGatherer do
  @moduledoc """
  Documentation for HunterGatherer.
  """

  @doc """
  Hello world.

  ## Examples

      iex> HunterGatherer.hello
      :world

  """

  defmodule Backpack do
    defstruct [:base, :pending, :good, :bad]

    def init(base) do
      %Backpack{
        base: URI.parse(base),
        pending: [base],
        good: MapSet.new,
        bad: MapSet.new
      }
    end

    def has_next_pending?(backpack) do
      length(backpack.pending) > 0
    end

    def get_next_pending(config) do
      [url|new_pending] = config.pending
      new_config = struct(config, pending: new_pending)
      {url, new_config}
    end

    def append_bad(backpack, url) do
      new_bad = backpack.bad |> MapSet.put(url)
      struct(backpack, bad: new_bad)
    end

    def append_good(backpack, url) do
      new_good = backpack.good |> MapSet.put(url)
      struct(backpack, good: new_good)
    end

    def append_pending(backpack, links) do
      links_not_checked = Enum.reject(links, fn(url) ->
        Backpack.has_been_processed?(backpack, url)
      end) |> Enum.map(fn(url) ->
        struct(URI.parse(url), fragment: nil) |> to_string
      end)
      new_pending = (backpack.pending ++ links_not_checked) |> Enum.uniq
      struct(backpack, pending: new_pending)
    end

    def has_been_processed?(backpack, url) do
      MapSet.member?(backpack.good, url) || MapSet.member?(backpack.bad, url)
    end

    def report(backpack) do
      IO.inspect backpack.bad
    end
  end

  def start(url) do
    backpack = Backpack.init(url)
    loop(backpack)
  end

  defp loop(backpack) do
    if Backpack.has_next_pending?(backpack) do
      {url, backpack} = Backpack.get_next_pending(backpack)

      if Backpack.has_been_processed?(backpack, url) do
        loop(backpack)
      else
        IO.puts url
        process_url(url, backpack) |> loop
      end
    else
      Backpack.report(backpack)
    end
  end

  defp process_url(url, backpack) do
    IO.puts length(backpack.pending)

    case HTTPoison.get(url, [], [follow_redirect: true, max_redirect: 5]) do
      {:ok, result} ->
        process_success(url, result, backpack)
      {:error, _} ->
        process_failure(url, backpack)
    end
  end

  defp process_failure(url, backpack) do
    Backpack.append_bad(backpack, url)
  end

  defp process_success(url, result, backpack) do
    case result.status_code do
      200 ->
        backpack = Backpack.append_good(backpack, url)
        
        case String.split(url, backpack.base |> to_string, parts: 2) do
          [_, _] ->
            links = result.body
              |> Floki.find("a")
              |> Floki.attribute("href")
              |> Enum.map(fn(url) -> URI.parse(url) end)
              |> Enum.map(fn(url) -> URI.merge(backpack.base, url) |> to_string end)
            backpack = Backpack.append_pending(backpack, links)
          [_] ->
            backpack
        end
      _ ->
        process_failure(url, backpack)
    end
  end
end

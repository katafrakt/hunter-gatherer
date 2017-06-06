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
        bad: Map.new
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

    def append_bad(backpack, url, reason) do
      new_bad = backpack.bad |> Map.put(url, reason)
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
      MapSet.member?(backpack.good, url) || Map.has_key?(backpack.bad, url)
    end

    def report(backpack) do
      backpack.bad |> Enum.each(fn({key, val}) -> IO.puts(key <> " - " <> format_error(val)) end)
    end

    defp format_error(error) when is_integer(error) do
      error |> to_string
    end

    defp format_error(error) do
      IO.inspect error
      elem(error.reason, 0) |> to_string
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
        case process_url(url, backpack) do
          {:ok, url, links} ->
            backpack
            |> Backpack.append_pending(links)
            |> Backpack.append_good(url)
          {:error, url, reason} ->
            backpack
            |> Backpack.append_bad(url, reason)
        end |> loop
      end
    else
      Backpack.report(backpack)
    end
  end

  defp process_url(url, backpack) do
    case HTTPoison.get(url, [], [follow_redirect: true, max_redirect: 5, ssl: [{:versions, [:'tlsv1.2']}]]) do
      {:ok, %{status_code: 200} = result} ->
        {:ok, url, get_links(url, result, backpack)}
      {:ok, result} ->
        {:error, url, result.status_code}
      {:error, error} ->
        {:error, url, error}
    end
  end

  defp get_links(url, result, backpack) do
    case String.split(url, backpack.base |> to_string, parts: 2) do
      [_, _] ->
        result.body
        |> Floki.find("a")
        |> Floki.attribute("href")
        |> Enum.map(fn(url) -> URI.parse(url) end)
        |> Enum.map(fn(url) -> URI.merge(backpack.base, url) |> to_string end)
      [_] ->
        []
    end
  end
end

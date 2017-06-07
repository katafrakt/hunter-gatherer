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

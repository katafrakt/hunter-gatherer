  defmodule Backpack do
    @moduledoc """
    Backpack is hunter-gatherer's most important piece of equipment. It stores a lot of things,
    from configuration to collection of processed and pending URLs.
    """

    defstruct [:base, :pending, :good, :bad]

    @doc """
    Initializes backpack.

    ## Parameters

    * `base` - base URL from which to start and which is used to determine whether URL is external or internal
    """
    def init(base) do
      %Backpack{
        base: URI.parse(base),
        pending: [base],
        good: MapSet.new,
        bad: Map.new
      }
    end

    @doc """
    Checks whethere there are any URLs left in pending list
    """
    def has_next_pending?(backpack) do
      length(backpack.pending) > 0
    end

    @doc """
    Gets the first link from pending list.

    It DOES NOT check if anything is there so should be used along with `has_next_pending?`.
    Returns tuple of URL and new backpack (with reduces pending list).
    """
    def get_next_pending(backpack) do
      [url|tail] = backpack.pending
      new_backpack = struct(backpack, pending: tail)
      {url, new_backpack}
    end

    @doc """
    Appends an URL to "bad" list along with reason why it's bad.
    Returns new backpack.
    """
    def append_bad(backpack, url, reason) do
      new_bad = backpack.bad |> Map.put(url, reason)
      struct(backpack, bad: new_bad)
    end

    @doc """
    Appends an URL to "good" list.
    Returns new backpack.
    """
    def append_good(backpack, url) do
      new_good = backpack.good |> MapSet.put(url)
      struct(backpack, good: new_good)
    end

    @doc """
    Appends new URLs to pending list.
    Also checks for duplicates and removes them.
    Returns new backpack.
    """
    def append_pending(backpack, links) do
      links_not_checked = Enum.map(links, fn(url) ->
        url = struct(URI.parse(url), fragment: nil) |> to_string
        Regex.replace(~r/ /, url, "%20")
      end) |> Enum.reject(fn(url) ->
        Backpack.has_been_processed?(backpack, url)
      end)
      new_pending = (backpack.pending ++ links_not_checked) |> Enum.uniq
      struct(backpack, pending: new_pending)
    end

    @doc """
    Checks if link has already been processed.
    """
    def has_been_processed?(backpack, url) do
      MapSet.member?(backpack.good, url) || Map.has_key?(backpack.bad, url)
    end
  end

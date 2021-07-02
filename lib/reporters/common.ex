defmodule HunterGatherer.Reporters.Common do
  @moduledoc false

  def select(format) do
    case format do
      "json" -> HunterGatherer.Reporters.Json
      "html" -> HunterGatherer.Reporters.Html
    end
  end

  def format_error(error) when is_integer(error) do
    error |> to_string
  end

  def format_error(error) do
    if is_tuple(error.reason) || is_map(error.reason) do
      elem(error.reason, 0) |> to_string
    else
      error.reason |> to_string
    end
  end
end

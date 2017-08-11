defmodule HunterGatherer.Reporter do
  alias HunterGatherer.HitCollector

  def generate_html_report(backpack) do
    filename = "report.html"
    {:ok, file} = File.open filename, [:write]

    data = backpack.bad
      |> Enum.map(fn({url, reason}) ->
        %{url: url, reason: format_error(reason), hits: HitCollector.get(url)}
      end)
      |> Enum.sort(&(&1.hits >= &2.hits))

    html = Mustachex.render_file("report_template.mustache", %{badurls: data})
    IO.binwrite(file, html)
  end

  defp format_error(error) when is_integer(error) do
    error |> to_string
  end

  defp format_error(error) do
    if is_tuple(error.reason) || is_map(error.reason) do
      elem(error.reason, 0) |> to_string
    else
      error.reason |> to_string
    end
  end
end

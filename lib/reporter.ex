defmodule HunterGatherer.Reporter do
  def generate_html_report(backpack) do
    filename = "report.html"
    {:ok, file} = File.open filename, [:write]

    data = backpack.bad |> Enum.map(fn({key, val}) ->
      [url: key, reason: format_error(val)]
    end)

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

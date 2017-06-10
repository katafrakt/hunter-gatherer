defmodule HunterGatherer.Reporter do
  def generate_html_report(backpack) do
    filename = "report.html"
    {:ok, file} = File.open filename, [:write]

    head = "
    <html>
    <body>
    <table>
    <h3>Bad URLs</h3>
    <tr>
    <th>URL</th>
    <th>reason</th>
    </tr>
    "

    data = backpack.bad |> Enum.map(fn({key, val}) ->
      "<tr><td>" <> key <> "</td><td>" <> format_error(val) <> "</td></tr>"
    end) |> Enum.join(~s(\n))

    foot = "</body</html>"

    IO.binwrite(file, head <> data <> foot)
  end

  defp format_error(error) when is_integer(error) do
    error |> to_string
  end

  defp format_error(error) do
    if is_map(error.reason) do
      elem(error.reason, 0) |> to_string
    else
      error.reason |> to_string
    end
  end
end

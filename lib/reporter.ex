defmodule HunterGatherer.Reporter do
  def generate_html_report(backpack) do
    filename = "report.html"
    {:ok, file} = File.open filename, [:write]

    template = """
    <html>
      <head>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/pure/1.0.0/pure-min.css" />
      </head>
      <body>
        <h3>Bad URLs</h3>
        <table class="pure-table pure-table-striped">
          <tr>
            <th>URL</th>
            <th>reason</th>
          </tr>
          {{#badurls}}
            <tr>
              <td><a href="{{url}}">{{url}}</a></td>
              <td>{{reason}}</td>
            </tr>
          {{/badurls}}
        </table>
      </body>
    </html>
    """

    data = backpack.bad |> Enum.map(fn({key, val}) ->
      [url: key, reason: format_error(val)]
    end)

    html = Mustachex.render(template, %{badurls: data})
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

defmodule FiveTwoOne.SfDataMffp.Impl do
  alias FiveTwoOne.SfDataMffp.Facility

  @behaviour FiveTwoOne.SfDataMffp.Behaviour

  @impl FiveTwoOne.SfDataMffp.Behaviour
  def get_all_facilities do
    Finch.build(:get, "https://data.sfgov.org/api/views/rqzj-sfat/rows.json?accessType=DOWNLOAD")
    |> Finch.request(FiveTwoOne.Finch)
    |> parse_response()
  end

  defp parse_response({:ok, %{status: 200, body: body}}) do
    with {:ok, body} <- Jason.decode(body) do
      columns =
        body["meta"]["view"]["columns"]
        |> Enum.map(& &1["name"])
        |> Enum.map(&Macro.underscore/1)

      rows = body["data"]

      facilities =
        rows
        |> Enum.map(fn row ->
          columns
          |> Enum.zip(row)
          |> Map.new()
        end)

      {:ok, facilities}
    end
  end

  defp parse_response({:error, reason}) do
    {:error, reason}
  end
end

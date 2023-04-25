defmodule FiveTwoOne.SfDataMffp do
  use GenServer
  require Logger

  @table_and_key :facilities

  def get_all_facilities do
    impl().get_all_facilities()
  end

  def get_all_facilities! do
    Logger.info("Fetching all facilities")

    case get_all_facilities() do
      {:ok, data} ->
        data
        |> Enum.filter(fn facility ->
          facility["food_items"] && facility["status"] == "APPROVED"
        end)
        |> IO.inspect(label: "Facilities with food items", limit: :infinity)
        |> Enum.map(fn facility ->
          %{
            id: facility["id"],
            applicant: facility["applicant"],
            food_items: facility["food_items"],
            latitude: facility["latitude"],
            longitude: facility["longitude"]
          }
        end)

      {:error, reason} ->
        raise reason
    end
  end

  def get_latest_facilities do
    :ets.lookup_element(@table_and_key, @table_and_key, 2)
  end

  def refresh do
    GenServer.call(__MODULE__, :refresh, 30_000)
  end

  defp impl do
    Application.get_env(:sf_data_mffp, :impl, FiveTwoOne.SfDataMffp.Impl)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(options) do
    :ets.new(@table_and_key, [:set, :public, :named_table])
    facilities = Keyword.get(options, :data) || get_all_facilities!()

    :ets.insert(@table_and_key, {@table_and_key, facilities})

    {:ok,
     %{
       can_update_after: Timex.shift(DateTime.utc_now(), minutes: 5)
     }}
  end

  @impl GenServer
  def handle_call(:refresh, _from, %{can_update_after: can_update_after} = state) do
    if DateTime.utc_now() > can_update_after do
      data = get_all_facilities!()

      new_state = %{
        data: data,
        last_updated: DateTime.utc_now()
      }

      {:reply, data, new_state}
    else
      {:reply, state[:data], state}
    end
  end
end

defmodule FiveTwoOne.SfDataMffp do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_all_facilities do
    impl().get_all_facilities()
  end

  def get_all_facilities! do
    case get_all_facilities() do
      {:ok, data} -> data
      {:error, reason} -> raise reason
    end
  end

  def refresh do
    GenServer.call(__MODULE__, :refresh)
  end

  defp impl do
    Application.get_env(:sf_data_mffp, :impl, FiveTwoOne.SfDataMffp.Impl)
  end

  @impl GenServer
  def init(options) do
    opts = %{
      last_updated: DateTime.utc_now(),
      # Using || so it doesn't retrieve if data is provided!
      data: Keyword.get(options, :data) || get_all_facilities!()
    }

    {:ok, opts}
  end

  @impl GenServer
  def handle_info(:refresh, _state) do
    new_state = %{
      data: get_all_facilities!(),
      last_updated: DateTime.utc_now()
    }

    {:noreply, new_state}
  end
end

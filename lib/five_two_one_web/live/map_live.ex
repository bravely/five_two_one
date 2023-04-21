defmodule FiveTwoOneWeb.MapLive do
  use Phoenix.LiveView

  alias FiveTwoOne.SfDataMffp

  def mount(_params, _session, socket) do
    Process.send_after(self(), :tick, 1000)
    {:ok, assign(socket, :count, 0)}
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 1000)
    {:noreply, assign(socket, :count, socket.assigns.count + 1)}
  end

  # Need a refresh

  def handle_event("refresh", _params, socket) do
    SfDataMffp.refresh()
    |> facility_permits_to_map_markers()

    {:noreply, socket}
  end

  defp facility_permits_to_map_markers(facility_permits) do
    facility_permits
    |> Enum.map(fn facility_permit ->
      %{
        lat: facility_permit.latitude,
        lng: facility_permit.longitude,
        infoWindow: %{
          content: """
          <div>
            <h3>#{facility_permit.facility_name}</h3>
            <p>#{facility_permit.facility_address}</p>
            <p>#{facility_permit.facility_city}, #{facility_permit.facility_state} #{facility_permit.facility_zip}</p>
            <p>#{facility_permit.permit_type}</p>
            <p>#{facility_permit.permit_status}</p>
            <p>#{facility_permit.permit_issued_date}</p>
          </div>
          """
        }
      }
    end)
  end

  def render(assigns) do
    ~H"""
    <h1>Five Two One</h1>
    <div>
      Map goes here! Count: <%= @count %>
      <button phx-click="refresh">Refresh</button>
    </div>
    <div id="map" phx-update="ignore"></div>
    """
  end

  attr :name, :string, required: true
  attr :lat, :float, required: true
  attr :lng, :float, required: true
  attr :status, :atom, values: [:listed, :option, :selected], default: :listed

  def map_marker(assigns) do
    ~H"""
    <leaflet-marker name={@name} lat={@lat} lng={@lng} status={@status} />
    """
  end
end

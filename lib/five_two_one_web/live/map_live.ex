defmodule FiveTwoOneWeb.MapLive do
  use Phoenix.LiveView

  alias FiveTwoOne.SfDataMffp

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :facilities, refresh_facilities())}
  end

  def handle_event("refresh", _params, socket) do
    facilities =
      socket.assigns.facilities
      |> Enum.filter(& &1.selected)
      |> Enum.map(& &1.id)
      |> refresh_facilities()

    {:noreply, assign(socket, :facilities, SfDataMffp.refresh())}
  end

  def refresh_facilities do
    SfDataMffp.get_latest_facilities()
    |> Enum.map(&Map.put(&1, :selected, false))
  end

  def refresh_facilities(selected_facility_ids) do
    refresh_facilities()
    |> Enum.map(fn %{id: id} = facility ->
      %{facility | selected: id in selected_facility_ids}
    end)
  end

  def handle_event("toggle_select", %{"facility_id" => facility_id}, socket) do
    facilities =
      socket.assigns.facilities
      |> Enum.map(fn
        %{id: ^facility_id} = facility -> %{facility | selected: !facility.selected}
        other -> other
      end)

    {:noreply, assign(socket, :facilities, facilities)}
  end

  def render(assigns) do
    ~H"""
    <h1>Five Two One</h1>
    <div>
      <button phx-click="refresh">Refresh</button>
    </div>
    <leaflet-map id="map" latitude="37.7749" longitude="-122.4194">
      <%= for facility <- @facilities do %>
        <%= map_marker(facility) %>
      <% end %>
    </leaflet-map>
    """
  end

  def map_marker(assigns) do
    ~H"""
    <leaflet-marker
      latitude={@latitude}
      longitude={@longitude}
      color={if @selected, do: "red", else: "blue"}
      phx-click="toggle_select"
      phx-value-facility_id={@id}
    />
    """
  end
end

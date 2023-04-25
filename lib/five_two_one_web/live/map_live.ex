defmodule FiveTwoOneWeb.MapLive do
  use Phoenix.LiveView

  alias FiveTwoOne.Game
  alias FiveTwoOne.SfDataMffp

  def mount(%{"game_id" => game_id}, _session, socket) do
    {game_pid, game} = Game.get_game(game_id)

    Phoenix.PubSub.subscribe(FiveTwoOne.PubSub, game_id)

    socket =
      socket
      |> assign(:game_pid, game_pid)
      |> assign(:facilities, game.options)
      |> assign(:round, game.round)

    {:ok, socket}
  end

  def handle_event("toggle_select", %{"facility_id" => facility_id}, socket) do
    game = Game.toggle_selected_facility(socket.assigns.game_pid, facility_id)

    socket =
      socket
      |> assign(:facilities, game.options)
      |> assign(:round, game.round)

    {:noreply, socket}
  end

  def handle_info({:game_update, game}, socket) do
    socket =
      socket
      |> assign(:facilities, game.options)
      |> assign(:round, game.round)

    {:noreply, socket}
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
      color={status_to_color(@status)}
      phx-click="toggle_select"
      phx-value-facility_id={@id}
    />
    """
  end

  def status_to_color(:selected), do: "red"
  def status_to_color(:option), do: "blue"
  def status_to_color(:invalid), do: "gray"
end

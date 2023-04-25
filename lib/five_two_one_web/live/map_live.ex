defmodule FiveTwoOneWeb.MapLive do
  use Phoenix.LiveView

  alias FiveTwoOne.Game
  alias FiveTwoOne.SfDataMffp

  def mount(%{"game_id" => game_id}, _session, socket) do
    {game_pid, game_state} = Game.join_game(game_id)

    Phoenix.PubSub.subscribe(FiveTwoOne.PubSub, game_id)

    socket =
      socket
      |> update_game_display(game_state)
      |> assign(:game_pid, game_pid)

    {:ok, socket}
  end

  def handle_event("toggle_select", %{"facility_id" => facility_id}, socket) do
    socket =
      update_game_display(
        socket,
        Game.toggle_selected_facility(socket.assigns.game_pid, facility_id)
      )

    {:noreply, socket}
  end

  def handle_event("submit_selection", _, socket) do
    socket =
      update_game_display(
        socket,
        Game.submit_selection(socket.assigns.game_pid)
      )

    {:noreply, socket}
  end

  def handle_info({:game_update, game_state}, socket) do
    {:noreply, update_game_display(socket, game_state)}
  end

  defp update_game_display(socket, game_state) do
    player = Map.get(game_state.players, self())

    facilities_with_player_selections =
      Enum.map(game_state.game.options, fn facility ->
        if Enum.member?(Enum.map(player.selection, & &1.id), facility.id) do
          Map.put(facility, :selected_by_color, player.color)
        else
          facility
        end
      end)

    socket
    |> assign(:facilities, facilities_with_player_selections)
    |> assign(:round, game_state.game.round)
    |> assign(:players, Map.values(game_state.players))
    |> assign(:player_color, player.color)
  end

  def render(assigns) do
    ~H"""
    <h1>Five Two One</h1>
    <leaflet-map id="map" latitude="37.7749" longitude="-122.4194">
      <%= for facility <- @facilities do %>
        <%= map_marker(facility) %>
      <% end %>
    </leaflet-map>
    <div>
      <h2>Round: <%= @round %></h2>
      <h2>Selected Facilities</h2>

      <%= for player <- @players do %>
        <div>
          <h3><%= player.color %></h3>
          <ul>
            <%= for facility <- player.selection do %>
              <li><%= facility.applicant %></li>
            <% end %>
          </ul>
          <%= if player.color == @player_color and selection_full?(player.selection, @round) do %>
            <button phx-click="submit_selection">Submit Selections</button>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp selection_full?(selection, 1), do: length(selection) >= 5
  defp selection_full?(selection, 2), do: length(selection) >= 2
  defp selection_full?(selection, 3), do: length(selection) >= 1

  def map_marker(assigns) do
    ~H"""
    <leaflet-marker
      latitude={@latitude}
      longitude={@longitude}
      color={@selected_by_color}
      phx-click="toggle_select"
      phx-value-facility_id={@id}
    >
      <h3><%= @applicant %></h3>
      <ul>
        <%= for food_item <- @food_items do %>
          <li><%= food_item %></li>
        <% end %>
      </ul>
      <p><%= @address %></p>
    </leaflet-marker>
    """
  end
end

defmodule FiveTwoOne.Game do
  use GenServer

  alias FiveTwoOne.Games.Supervisor, as: GameSupervisor
  alias FiveTwoOne.Games.Registry, as: GameRegistry
  alias FiveTwoOne.SfDataMffp

  def join_game(pid) when is_pid(pid) do
    GenServer.call(pid, :join_game)
  end

  def join_game(id) do
    {:ok, pid} =
      case Registry.lookup(GameRegistry, id) do
        [{pid, _}] -> {:ok, pid}
        [] -> DynamicSupervisor.start_child(GameSupervisor, child_spec([id, self()]))
      end

    {pid, GenServer.call(pid, :join_game)}
  end

  def toggle_selected_facility(pid, selection_id) do
    GenServer.call(pid, {:toggle_selection, selection_id})
  end

  def submit_selection(pid) do
    GenServer.call(pid, :submit_selection)
  end

  # Private API

  def start_link(id, starting_player_pid) do
    GenServer.start_link(__MODULE__, [id, starting_player_pid],
      name: {:via, Registry, {GameRegistry, id}}
    )
  end

  def child_spec([id, _starting_player_pid] = init_args) do
    %{
      id: id,
      start: {__MODULE__, :start_link, init_args}
    }
  end

  def init([id, initial_player_pid]) do
    options =
      SfDataMffp.get_latest_facilities()
      |> Enum.map(&Map.put(&1, :selected_by_color, "grey"))

    state = %{
      game_id: id,
      players: %{initial_player_pid => %{color: get_unused_color(%{}), selection: []}},
      game: %{round: 1, last_round_selector: nil, options: options}
    }

    {:ok, state}
  end

  @available_colors ~w(
    blue
    red
    green
    orange
    yellow
    violet
  )

  defp get_unused_color(players) do
    player_colors =
      players
      |> Map.values()
      |> Enum.map(& &1.color)

    case @available_colors -- player_colors do
      [] -> Enum.random(@available_colors)
      list -> Enum.random(list)
    end
  end

  def handle_call(:join_game, {from, _ref}, state) do
    state = %{
      state
      | players:
          Map.put(state.players, from, %{color: get_unused_color(state.players), selection: []})
    }

    {:reply, state, state}
  end

  def handle_call(
        {:toggle_selection, selection_id},
        {from, _ref},
        state
      ) do
    player_state = Map.get(state.players, from)

    if can_add_selection?(player_state, state.game.round) do
      new_selection =
        if Enum.member?(Enum.map(player_state.selection, & &1.id), selection_id) do
          Enum.reject(player_state.selection, &(&1.id == selection_id))
        else
          player_state.selection ++ [Enum.find(state.game.options, &(&1.id == selection_id))]
        end

      new_state = %{
        state
        | players: Map.put(state.players, from, %{player_state | selection: new_selection})
      }

      Phoenix.PubSub.broadcast(FiveTwoOne.PubSub, state.game_id, {:game_update, new_state})
      {:reply, new_state, new_state}
    else
      {:reply, state, state}
    end
  end

  defp can_add_selection?(%{selection: selection}, 1), do: length(selection) < 6
  defp can_add_selection?(%{selection: selection}, 2), do: length(selection) < 3
  defp can_add_selection?(%{selection: selection}, 3), do: length(selection) < 2

  def selection_count_for_round(1), do: 5
  def selection_count_for_round(2), do: 2
  def selection_count_for_round(3), do: 1
  # So it's never allowed
  def selection_count_for_round(_0), do: -1

  def handle_call(:submit_selection, {from, _ref}, state) do
    player_state = Map.get(state.players, from)

    if length(player_state.selection) == selection_count_for_round(state.game.round) do
      player = %{player_state | selection: []}

      options =
        Enum.map(state.game.options, fn option ->
          if Enum.member?(Enum.map(player_state.selection, & &1.id), option.id) do
            Map.put(option, :selected_by_color, player_state.color)
          else
            option
          end
        end)

      new_state = %{
        state
        | players: Map.put(state.players, from, player),
          game: %{state.game | round: state.game.round + 1, options: options}
      }

      Phoenix.PubSub.broadcast(FiveTwoOne.PubSub, state.game_id, {:game_update, new_state})
      {:reply, new_state, new_state}
    else
      {:reply, state, state}
    end
  end
end

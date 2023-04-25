defmodule FiveTwoOne.Game do
  use GenServer

  alias FiveTwoOne.Games.Supervisor, as: GameSupervisor
  alias FiveTwoOne.Games.Registry, as: GameRegistry
  alias FiveTwoOne.SfDataMffp

  def get_game(pid) when is_pid(pid) do
    GenServer.call(pid, :get_game)
  end

  def get_game(id) do
    {:ok, pid} =
      case Registry.lookup(GameRegistry, id) do
        [{pid, _}] -> {:ok, pid}
        [] -> DynamicSupervisor.start_child(GameSupervisor, child_spec(id))
      end

    {pid, GenServer.call(pid, :get_game)}
  end

  def toggle_selected_facility(pid, selection_id) do
    GenServer.call(pid, {:toggle_selection, selection_id})
  end

  # Private API

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: {:via, Registry, {GameRegistry, id}})
  end

  def child_spec(id) do
    %{
      id: id,
      start: {__MODULE__, :start_link, [id]}
    }
  end

  def init(id) do
    options =
      SfDataMffp.get_latest_facilities()
      |> Enum.take_random(5)
      |> Enum.map(&Map.put(&1, :status, :option))

    {:ok, %{game_id: id, round: 1, options: options}}
  end

  def handle_call(:get_game, _from, state) do
    {:reply, state, state}
  end

  def handle_call(
        {:toggle_selection, selection_id},
        _from,
        %{round: 1, options: options} = state
      ) do
    options = toggle_selection(options, selection_id)
    num_selected = Enum.count(options, &(&1.status == :selected))

    if num_selected == 2 do
      options =
        Enum.map(options, fn
          %{status: :selected} = facility -> %{facility | status: :option}
          other_facility -> %{other_facility | status: :invalid}
        end)
    end

    new_game_state = %{state | options: options}

    Phoenix.PubSub.broadcast(FiveTwoOne.PubSub, state.game_id, {:game_update, new_game_state})
    {:reply, new_game_state, new_game_state}
  end

  defp toggle_selection(facilities, selection_id) do
    Enum.map(facilities, fn
      %{id: ^selection_id} = facility -> toggle_facility(facility)
      other -> other
    end)
  end

  defp toggle_facility(%{status: :invalid} = facility), do: facility
  defp toggle_facility(%{status: :option} = facility), do: %{facility | status: :selected}
  defp toggle_facility(%{status: :selected} = facility), do: %{facility | status: :option}
end

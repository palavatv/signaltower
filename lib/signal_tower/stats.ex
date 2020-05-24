defmodule SignalTower.Stats do
  alias SignalTower.Stats.RoomSession
  alias SignalTower.PrometheusStats
  use GenServer

  ## API ##

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## Callbacks ##

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_cast({:room_created, pid}, room_sessions) do
    time = DateTime.utc_now()
    new_session = %RoomSession{pid: pid, create_time: time, peak_time: time}
    PrometheusStats.room_created()
    {:noreply, Map.put(room_sessions, pid, new_session)}
  end

  @impl GenServer
  def handle_cast({:room_closed, pid}, room_sessions) do
    case Map.pop(room_sessions, pid) do
      {nil, _} ->
        {:noreply, room_sessions}

      {room_session, _} ->
        room_session_duration =
          DateTime.diff(DateTime.utc_now(), room_session.create_time, :millisecond)

        PrometheusStats.room_closed(room_session_duration, room_session.peak_user_count)
        {:noreply, room_sessions}
    end
  end

  @impl GenServer
  def handle_cast({:peer_joined, pid, count}, room_sessions) do
    PrometheusStats.join()

    if room_sessions[pid] && room_sessions[pid].peak_user_count < count do
      updated_room_sessions =
        room_sessions
        |> put_in([pid, Access.key(:peak_time)], DateTime.utc_now())
        |> put_in([pid, Access.key(:peak_user_count)], count)

      {:noreply, updated_room_sessions}
    else
      {:noreply, room_sessions}
    end
  end

  @impl GenServer
  def handle_cast({:peer_left, _pid}, state) do
    PrometheusStats.leave()
    {:noreply, state}
  end
end

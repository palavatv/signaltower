defmodule SignalTower.Stats do
  alias SignalTower.Stats.RoomSession
  use GenServer

  ## API ##

  def start_link(log_file) do
    GenServer.start_link(__MODULE__, log_file, name: __MODULE__)
  end

  ## Callbacks ##

  def init(log_file) do
    file = File.open!(log_file, [:write, :append])
    {:ok, {file, %{}}}
  end

  def handle_cast({:room_created, pid}, {file, room_sessions}) do
    Process.monitor(pid)
    time = DateTime.utc_now()
    new_session = %RoomSession{pid: pid, create_time: time, peak_time: time}
    {:noreply, {file, Map.put(room_sessions, pid, new_session)}}
  end

  def handle_cast({:update_room_peak, pid, count}, {file, room_sessions}) do
    if room_sessions[pid] && room_sessions[pid].peak_user_count < count do
      updated_room_sessions =
        room_sessions
        |> put_in([pid, Access.key(:peak_time)], DateTime.utc_now())
        |> put_in([pid, Access.key(:peak_user_count)], count)

      {:noreply, {file, updated_room_sessions}}
    else
      {:noreply, {file, room_sessions}}
    end
  end

  def handle_info({:DOWN, _ref, _, pid, _}, state = {file, room_sessions}) do
    case Map.pop(room_sessions, pid) do
      {nil, _} ->
        {:noreply, state}

      {s, updated_room_sessions} ->
        log_line =
          Enum.join(
            [
              s.create_time |> DateTime.to_string(),
              s.peak_time |> DateTime.to_string(),
              DateTime.utc_now() |> DateTime.to_string(),
              s.peak_user_count
            ],
            ","
          )

        IO.binwrite(file, log_line <> "\n")
        {:noreply, {file, updated_room_sessions}}
    end
  end
end

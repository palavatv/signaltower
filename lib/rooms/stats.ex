defmodule SignalTower.Stats.RoomSession do
  defstruct pid: nil,
            create_time: DateTime.utc_now(),
            peak_time: DateTime.utc_now(),
            peak_user_count: 0
end

defmodule SignalTower.Stats do
  alias SignalTower.Stats.RoomSession
  use GenServer

  ## API ##

  def start_link(logfile) do
    GenServer.start_link(__MODULE__, logfile, name: __MODULE__)
  end

  ## Callbacks ##

  def init(logfile) do
    file = File.open!(logfile, [:write, :append])
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

defmodule SignalTower.PrometheusStats do
  use Prometheus.Metric
  @counter [name: :palava_joined_room_total, labels: [], help: "Number of peers joined a room"]

  @counter [name: :palava_leave_room_total, labels: [], help: "Number of peers left a room"]

  def reset() do
    Counter.reset(name: :palava_joined_room_total)
    Counter.reset(name: :palava_leave_room_total)
  end

  def join() do
    Counter.inc(name: :palava_joined_room_total)
  end

  def leave() do
    Counter.inc(name: :palava_leave_room_total)
  end

  def to_string() do
    Prometheus.Format.Text.format()
  end
end

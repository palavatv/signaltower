defmodule SignalTower.Session do
  alias SignalTower.Room
  alias SignalTower.MsgIntegrity

  def init() do
    self()
    |> inspect()
    |> :base64.encode()
    |> (&Kernel.<>("user_", &1)).()
    |> String.to_atom()
    |> (&Process.register(self(), &1)).()
  end

  def handle_message(msg, {room, ltt}) do
    case MsgIntegrity.check(msg, room) do
      {:ok, msg} ->
        incoming_message(msg, {room, ltt})

      {:error, error} ->
        send_error(error, msg)
        room
    end
  end

  defp incoming_message(msg = %{"event" => "join_room"}, {_, last_turn_timestamp}) do
    Room.join_and_monitor(msg["room_id"], msg["status"], last_turn_timestamp)
  end

  defp incoming_message(msg = %{"event" => "leave_room"}, {room, ltt}) do
    if room do
      case GenServer.call(room.pid, {:leave, room.own_id}) do
        :ok ->
          {nil, ltt}

        :error ->
          send_error("You are not currently in a room, so you can not leave it", msg)
          {room, ltt}
      end
    else
      send_error("You are not currently in a room, so you can not leave it", msg)
      {room, ltt}
    end
  end

  defp incoming_message(msg = %{"event" => "send_to_peer"}, {room, ltt}) do
    GenServer.cast(room.pid, {:send_to_peer, msg["peer_id"], msg["data"], room.own_id})
    {room, ltt}
  end

  defp incoming_message(msg = %{"event" => "update_status"}, {room, ltt}) do
    GenServer.cast(room.pid, {:update_status, room.own_id, msg["status"]})
    {room, ltt}
  end

  defp incoming_message(%{"event" => "ping"}, state) do
    send(
      self(),
      {:to_user,
       %{
         event: "pong"
       }}
    )

    state
  end

  # invoked when a room exits
  def handle_exit_message(pid, room, status, ltt) do
    if room && pid == room.pid && status != :normal do
      # current room died => automatic rejoin
      Room.join_and_monitor(room.id, room.own_status, ltt)
    else
      {nil, ltt}
    end
  end

  defp send_error(error, received_msg) do
    send(
      self(),
      {:to_user,
       %{
         event: "error",
         description: error,
         received_msg: received_msg
       }}
    )
  end
end

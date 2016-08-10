defmodule SignalTower.RoomMembership do
  defstruct id: "", pid: nil, own_id: "", own_status: %{}
end

defmodule SignalTower.Session do
  alias SignalTower.Room
  alias SignalTower.MsgIntegrity
  use GenServer

  def handle_message(msg, room) do
    case MsgIntegrity.check(msg, room) do
      {:ok, msg} ->
        incoming_message(msg, room)
      {:error, error} ->
        send_error(error, msg)
        room
    end
  end

  defp incoming_message(msg = %{"event" => "join_room"}, _) do
    Room.join_and_monitor(msg["room_id"], msg["status"])
  end

  defp incoming_message(msg = %{"event" => "leave_room"}, room) do
    if room do
      GenServer.cast room.pid, {:leave, room.own_id}
    else
      send_error("You are not currently in a room, so you can not leave it", msg)
    end
    room
  end

  defp incoming_message(msg = %{"event" => "send_to_peer"}, room) do
    GenServer.cast room.pid, {:send_to_peer, msg["peer_id"], msg["data"], room.own_id}
    room
  end

  defp incoming_message(msg = %{"event" => "update_status"}, room) do
    GenServer.cast room.pid, {:update_status, room.own_id, msg["status"]}
    room
  end

  # invoked when a room or the client exits
  def handle_exit_message(pid, room) do
    if pid == room.pid do
      # current room died => automatic rejoin
      Room.join_and_monitor(room.id, room.own_status)
    else
      room
    end
  end

  defp send_error(error, received_msg) do
    send self(), {:to_user, %{
      event: "error",
      description: error,
      received_msg: received_msg
    }}
  end
end

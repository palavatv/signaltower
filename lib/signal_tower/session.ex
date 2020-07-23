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

  def handle_message(msg, state) do
    case MsgIntegrity.check(msg, state.room) do
      {:ok, msg} ->
        incoming_message(msg, state)

      {:error, error} ->
        send_error(error, msg)
        state
    end
  end

  defp incoming_message(msg = %{"event" => "join_room"}, state) do
    Room.join_and_monitor(msg["room_id"], msg["status"], state.turn_token_expiry)
  end

  defp incoming_message(msg = %{"event" => "leave_room"}, state = %{room: room}) do
    if room do
      case GenServer.call(room.pid, {:leave, room.own_id}) do
        :ok ->
          %{state | room: nil}

        :error ->
          send_error("You are not currently in a room, so you can not leave it", msg)
          state
      end
    else
      send_error("You are not currently in a room, so you can not leave it", msg)
      state
    end
  end

  defp incoming_message(msg = %{"event" => "send_to_peer"}, state = %{room: room}) do
    GenServer.cast(room.pid, {:send_to_peer, msg["peer_id"], msg["data"], room.own_id})
    state
  end

  defp incoming_message(msg = %{"event" => "update_status"}, state = %{room: room}) do
    GenServer.cast(room.pid, {:update_status, room.own_id, msg["status"]})
    state
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
  def handle_exit_message(
        pid,
        status,
        state = %{room: room, turn_token_expiry: turn_token_expiry}
      ) do
    if room && pid == room.pid && status != :normal do
      # current room died => automatic rejoin
      Room.join_and_monitor(room.id, room.own_status, turn_token_expiry)
    else
      state
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

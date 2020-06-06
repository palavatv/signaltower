defmodule SignalTower.MsgIntegrity do
  @room_messages ["update_status", "send_to_peer", "add_user_to_call", "leave_room"]

  def check(%{"event" => event} = msg, room) do
    with msg = fill_optional(msg),
         :ok <- check_completeness(msg),
         :ok <- check_room_event(room, event),
         do: {:ok, msg}
  end

  defp fill_optional(msg) do
    if msg["event"] == "join_room" && !msg["status"] do
      Map.put(msg, "status", %{})
    else
      msg
    end
  end

  defp check_completeness(msg = %{"event" => event}) do
    if complete?(event, msg),
      do: :ok,
      else: {:error, "unknown event name or missing/incorrect field(s)"}
  end

  defp complete?("join_room", msg) do
    is_binary(msg["room_id"]) && is_map(msg["status"]) &&
      (!msg["users_to_call"] || is_list(msg["users_to_call"]))
  end

  defp complete?("send_to_peer", msg), do: is_binary(msg["peer_id"]) && is_map(msg["data"])
  defp complete?("update_status", msg), do: is_map(msg["status"])
  defp complete?("leave_room", _msg), do: true
  defp complete?("ping", _msg), do: true
  defp complete?(_, _), do: false

  defp check_room_event(room, event) do
    if room || !Enum.member?(@room_messages, event) do
      if valid_room_event?(room, event) do
        :ok
      else
        {:error,
         "You can only join one room with one session. Leave your current room before joining a new one."}
      end
    else
      {:error, "Action only possible when in a room"}
    end
  end

  defp valid_room_event?(room, "join_room") when not is_nil(room), do: false
  defp valid_room_event?(_room, _event), do: true
end

defmodule SignalTower.MsgIntegrity do
  def check(msg, room) do
    with  msg = prepare_message(msg),
          :ok <- check_completeness(msg),
          :ok <- room_test(room, msg),
      do: {:ok, msg}
  end

  defp prepare_message(msg) do
    msg
    |> keys_to_strings()
    |> fill_optional()
  end

  defp keys_to_strings(msg) do
    msg
    |> Stream.map(fn ({key, value}) -> {to_string(key), value} end)
    |> Enum.into(%{})
  end

  defp fill_optional(msg) do
    msg = cond do
      msg["event"] == "join_room" && !msg["status"] ->
        Map.put msg, "status", %{}
      true -> msg
    end
    msg
  end

  defp check_completeness(msg) do
    complete = case msg["event"] do
      "join_room" ->
        is_binary(msg["room_id"]) && is_map(msg["status"]) &&
        (!msg["users_to_call"] || is_list(msg["users_to_call"]))
      "leave_room" -> is_binary(msg["room_id"])
      "send_to_peer" -> is_binary(msg["peer_id"]) && is_map(msg["data"])
      "update_status" -> is_map(msg["status"])
      _ -> false
    end

    case complete do
      true -> :ok
      false -> {:error, "unknown event name or missing/incorrect field(s)"}
    end
  end

  defp room_test(room, msg) do
    room_messages = ["update_status", "send_to_peer", "add_user_to_call", "leave_room"]
    if room || !Enum.member?(room_messages, msg["event"]) do
      if room && msg["event"] == "join_room" do
        {:error, "You can only join one room with one session. Leave your current room before joining a new one"}
      else
        :ok
      end
    else
      {:error, "Action only possible when in a room"}
    end
  end
end

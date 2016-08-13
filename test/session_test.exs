defmodule SessionTest do
  use ExUnit.Case, async: true

  alias SignalTower.Session

  test "join and leave with registered users" do
    host_pid = self()

    _client1 = create_client fn _ ->
      Session.handle_message %{
        event: "join_room",
        room_id: "s-room1",
        status: %{user: "0"}
      }, nil
      assert_receive {:to_user, %{
        event: "joined_room",
        own_id: "0",
        peers: []
      }}, 1000

      send host_pid, :break

      assert_receive {:to_user, %{
        event: "new_peer",
        peer_id: "1",
        status: %{user: "1"}
      }}, 1000

      assert_receive {:to_user, %{
        event: "peer_left",
        sender_id: "1"
      }}, 1000
    end
    wait_for_breaks(1)

    _client2 = create_client nil, true, fn _ ->
      Session.handle_message %{
        event: "join_room",
        room_id: "s-room1",
        status: %{user: "1"}
      }, nil

      assert_receive {:to_user, %{
        event: "joined_room",
        own_id: "1",
        peers: [%{peer_id: "0", status: %{user: "0"}}]
      }}, 1000
    end
    wait_for_breaks(2)
  end

  test "leave explicitly" do
    _client1 = create_client "s-room13", fn room ->
      Session.handle_message %{
        event: "leave_room",
        room_id: "s-room13"
      }, room
    end

    _client2 = create_client "s-room13", fn _ ->
      assert_receive {:to_user, %{event: "peer_left", sender_id: "0"}}, 1000
    end
    wait_for_breaks(2)
  end

  test "send to peer" do
    _client1 = create_client "s-room5", fn room ->
      Session.handle_message %{
        event: "send_to_peer",
        peer_id: "1",
        data: %{some: "data"}
      }, room
    end

    _client2 = create_client "s-room5", fn _ ->
      assert_receive {:to_user, %{
        some: "data",
        sender_id: "0"
      }}, 1000
    end
    wait_for_breaks(2)
  end

  test "update status" do
    _client1 = create_client "s-room6", fn room ->
      Session.handle_message %{
        event: "update_status",
        status: %{some: "status"}
      }, room
    end

    _client2 = create_client "s-room6", fn _ ->
      assert_receive {:to_user, %{
        event: "peer_updated_status",
        sender_id: "0",
        status: %{some: "status"}
      }}, 1000
    end
    wait_for_breaks(2)
  end

  test "not possible to use certain events when not in a room" do
    _client1 = create_client fn _ ->
      room = Session.handle_message %{
        event: "update_status",
        status: %{new: "status"}
      }, nil
      assert_receive {:to_user, m = %{event: "error"}}
      assert m[:description] == "Action only possible when in a room"

      Session.handle_message %{
        event: "send_to_peer",
        peer_id: "some_peer",
        data: %{some: "data"}
      }, room
      assert_receive {:to_user, m = %{event: "error"}}
      assert m[:description] == "Action only possible when in a room"
    end
    wait_for_breaks(1)
  end

  defp wait_for_breaks(n) when n > 0 do
    1..n |> Enum.each(fn _ -> assert_receive :break, 10000 end)
  end

  defp create_client room_id \\ nil, leave_after_finish \\ false, fun do
    host = self()

    pid = spawn_link fn ->
      room = case room_id do
        nil ->
          send host, :start
          nil
        room_id -> join_room(room_id, host)
      end
      fun.(room)
      send host, :break
      unless leave_after_finish, do: :timer.sleep(:infinity)
    end
    assert_receive :start
    pid
  end

  defp join_room(room_id, host) do
    room = Session.handle_message %{
      event: "join_room",
      room_id: room_id,
      status: %{local: "status"},
    }, nil
    if host, do: send host, :start
    assert_receive {:to_user, m}, 1000 # joined_room
    if length(m[:peers]) == 0, do: assert_receive({:to_user, %{event: "new_peer"}}, 1000) # wait for second peer
    room
  end
end

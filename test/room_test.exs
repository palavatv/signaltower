defmodule RoomTest do
  use ExUnit.Case, async: true

  alias SignalTower.RoomSupervisor
  
  test "r-room exists" do
    create_room("r-room")
    Process.registered |> Enum.member?(:"room_r-room") |> assert
  end

  test "join room" do
    room_pid = create_room("r-room2")

    _user1 = spawn_user room_pid, fn ->
      assert_receive {:to_user, %{
        event: "new_peer",
        peer_id: "1",
        status: %{user: "1"},
      }}, 1000
    end

    _user2 = spawn_user_no_join fn ->
      GenServer.call room_pid, {:join, self(), %{user: "1"}}

      assert_receive {:to_user, %{
        event: "joined_room",
        own_id: "1",
        peers: [%SignalTower.RoomMember{peer_id: "0", status: %{standard: "status"}}]
      }}, 1000
    end

    wait_for_breaks(2)
  end

  test "send to peer" do
    room_pid = create_room("r-room3")

    _user1 = spawn_user room_pid, fn ->
      assert_receive {:to_user, %{event: "new_peer"}}, 1000
      assert_receive {:to_user, %{
        hello: "world",
        sender_id: "1"
      }}, 1000
    end
    
    _user2 = spawn_user room_pid, fn ->
      GenServer.cast room_pid, {:send_to_peer, "0", %{hello: "world"}, "1"}
    end

    wait_for_breaks(2)
  end

  test "update status" do
    room_pid = create_room("r-room4")
    join_room(self(), room_pid)

    spawn_user room_pid, fn ->
      GenServer.cast room_pid, {:update_status, "1", %{new: "status"}}
    end
    assert_receive _, 1000 # new_peer

    assert_receive {:to_user, %{
      event: "peer_updated_status",
      sender_id: "1",
      status: %{new: "status"}
    }}, 1000
  end

  test "leave room" do
    room_pid = create_room("r-room5")
    join_room(self(), room_pid)

    spawn_user room_pid, fn ->
      GenServer.cast room_pid, {:leave, "1"}
    end
    assert_receive _, 1000 # new peer

    assert_receive {:to_user, %{
      event: "peer_left",
      sender_id: "1"
    }}, 1000 # peer left
  end

  # session process dies
  test "user leaves room when his session dies" do
    room_pid = create_room("r-room6")
    join_room(self(), room_pid)

    spawn_link fn ->
      join_room(self(), room_pid)
      # just leave
    end

    assert_receive _, 1000 # new_peer
    assert_receive {:to_user, %{
      event: "peer_left",
      sender_id: "1"
    }}, 1000
  end

  test "room exits when last active user is gone" do
    room_pid = create_room("r-room7")
    Process.monitor(room_pid)
    join_room(self(), room_pid)
    GenServer.cast room_pid, {:leave, "0"}
    assert_receive {:DOWN, _, :process, _, _}
  end

  defp create_room(room_id) do
    RoomSupervisor.get_room(room_id)
  end

  defp join_room(pid, room_pid) do
    GenServer.call room_pid, {:join, pid, %{standard: "status"}}
    assert_receive {:to_user, %{event: "joined_room"}}, 1000
  end

  defp wait_for_breaks(n) when n > 0 do
    1..n |> Enum.each(fn _ -> assert_receive :break, 10000 end)
  end

  defp spawn_user(room_pid, fun) do
    host = self()
    user_pid = spawn_link fn ->
      pid = self()
      join_room(pid, room_pid)
      send host, :start
      fun.()
      send host, :break
      :timer.sleep(:infinity)
    end
    assert_receive :start
    user_pid
  end

  defp spawn_user_no_join(fun) do
    host = self()
    user_pid = spawn_link fn ->
      send host, :start
      fun.()
      send host, :break
      :timer.sleep(:infinity)
    end

    assert_receive :start
    user_pid
  end
end

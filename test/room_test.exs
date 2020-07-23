defmodule RoomTest do
  use ExUnit.Case, async: true
  import TestHelper

  test "r-room exists" do
    create_room("r-room")
    Process.registered() |> Enum.member?(:"room_r-room") |> assert
  end

  test "join room" do
    room_pid = create_room("r-room2")

    _user1 =
      spawn_user(room_pid, fn _ ->
        assert_receive {:to_user,
                        %{
                          event: "new_peer",
                          peer_id: _,
                          status: %{user: "1"}
                        }},
                       1000
      end)

    _user2 =
      spawn_user_no_join(fn ->
        GenServer.call(room_pid, {:join, self(), %{user: "1"}, 0})

        assert_receive {:to_user,
                        %{
                          event: "joined_room",
                          own_id: _,
                          peers: [
                            %SignalTower.Room.Member{peer_id: _, status: %{standard: "status"}}
                          ]
                        }},
                       1000
      end)

    wait_for_breaks(2)
  end

  test "join room with turn" do
    System.put_env("SIGNALTOWER_TURN_SECRET", "verysecretpassphrase1234")
    room_pid = create_room("r-room3")

    # no token produced yet
    spawn_user_no_join(fn ->
      GenServer.call(room_pid, {:join, self(), %{user: "1"}, 0})
      receive_and_check_turn_credentials(0)
    end)

    # previous token is depleted
    spawn_user_no_join(fn ->
      previous_expiry = System.os_time(:second) - 2000
      GenServer.call(room_pid, {:join, self(), %{user: "1"}, previous_expiry})
      receive_and_check_turn_credentials(previous_expiry)
    end)

    # previous token is still valid
    spawn_user_no_join(fn ->
      previous_expiry = System.os_time(:second) + 2000
      GenServer.call(room_pid, {:join, self(), %{user: "1"}, previous_expiry})
      receive_and_check_turn_credentials(previous_expiry)
    end)

    wait_for_breaks(2)
  end

  test "send to peer" do
    room_pid = create_room("r-room4")

    user1 =
      spawn_user(room_pid, fn own_id ->
        assert_receive {:to_user, %{event: "new_peer"}}, 1000

        assert_receive peer_id, 1000

        GenServer.cast(room_pid, {:send_to_peer, peer_id, %{hello: "world"}, own_id})
      end)

    _user2 =
      spawn_user(room_pid, fn own_id ->
        send(user1, own_id)

        assert_receive {:to_user,
                        %{
                          hello: "world",
                          sender_id: _
                        }},
                       1000
      end)

    wait_for_breaks(2)
  end

  test "update status" do
    room_pid = create_room("r-room5")
    join_room(self(), room_pid)

    spawn_user(room_pid, fn own_id ->
      GenServer.cast(room_pid, {:update_status, own_id, %{new: "status"}})
    end)

    # new_peer
    assert_receive _, 1000

    assert_receive {:to_user,
                    %{
                      event: "peer_updated_status",
                      sender_id: _,
                      status: %{new: "status"}
                    }},
                   1000
  end

  test "leave room" do
    room_pid = create_room("r-room6")
    join_room(self(), room_pid)

    spawn_user(room_pid, fn own_id ->
      GenServer.call(room_pid, {:leave, own_id})
    end)

    # new peer
    assert_receive _, 1000

    assert_receive {:to_user,
                    %{
                      event: "peer_left",
                      sender_id: _
                    }},
                   # peer left
                   1000
  end

  # session process dies
  test "user leaves room when his session dies" do
    room_pid = create_room("r-room7")
    join_room(self(), room_pid)

    spawn_link(fn ->
      join_room(self(), room_pid)
      # just leave
    end)

    # new_peer
    assert_receive _, 1000

    assert_receive {:to_user,
                    %{
                      event: "peer_left",
                      sender_id: _
                    }},
                   1000
  end

  test "room exits when last active user is gone" do
    room_pid = create_room("r-room8")
    Process.monitor(room_pid)
    own_id = join_room(self(), room_pid)
    GenServer.call(room_pid, {:leave, own_id})
    assert_receive {:DOWN, _, :process, _, _}
  end

  defp create_room(room_id) do
    SignalTower.Room.create(room_id)
  end

  defp join_room(pid, room_pid) do
    GenServer.call(room_pid, {:join, pid, %{standard: "status"}, 0})
    assert_receive {:to_user, %{event: "joined_room", own_id: own_id}}, 1000
    own_id
  end

  defp spawn_user(room_pid, fun) do
    host = self()

    user_pid =
      spawn_link(fn ->
        pid = self()
        own_id = join_room(pid, room_pid)
        send(host, :start)
        fun.(own_id)
        send(host, :break)
        :timer.sleep(:infinity)
      end)

    assert_receive :start
    user_pid
  end

  defp spawn_user_no_join(fun) do
    host = self()

    user_pid =
      spawn_link(fn ->
        send(host, :start)
        fun.()
        send(host, :break)
        :timer.sleep(:infinity)
      end)

    assert_receive :start
    user_pid
  end
end

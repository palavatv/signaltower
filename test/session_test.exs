defmodule SessionTest do
  use ExUnit.Case, async: true
  import TestHelper

  alias SignalTower.Session

  @initial_state %{room: nil, turn_token_expiry: 0}

  test "join and leave with registered users" do
    host_pid = self()

    _client1 =
      create_client(fn _, _ ->
        Session.handle_message(
          %{
            "event" => "join_room",
            "room_id" => "s-room1",
            "status" => %{user: "0"}
          },
          @initial_state
        )

        assert_receive {:to_user,
                        %{
                          event: "joined_room",
                          own_id: _,
                          peers: []
                        }},
                       1000

        send(host_pid, :break)

        assert_receive {:to_user,
                        %{
                          event: "new_peer",
                          peer_id: _,
                          status: %{user: "1"}
                        }},
                       1000

        assert_receive {:to_user,
                        %{
                          event: "peer_left",
                          sender_id: _
                        }},
                       1000
      end)

    wait_for_breaks(1)

    _client2 =
      create_client(nil, true, fn _, _ ->
        Session.handle_message(
          %{
            "event" => "join_room",
            "room_id" => "s-room1",
            "status" => %{user: "1"}
          },
          @initial_state
        )

        assert_receive {:to_user,
                        %{
                          event: "joined_room",
                          own_id: _,
                          peers: [%{peer_id: _, status: %{user: "0"}}]
                        }},
                       1000
      end)

    wait_for_breaks(2)
  end

  test "join and check turn expiry" do
    System.put_env("SIGNALTOWER_TURN_SECRET", "verysecretpassphrase1234")

    # no token produced yet
    Session.handle_message(
      %{
        "event" => "join_room",
        "room_id" => "s-room1",
        "status" => %{user: "0"}
      },
      @initial_state
    )

    receive_and_check_turn_credentials(0)

    # previous token is depleted
    previous_expiry = System.os_time(:second) - 2000

    Session.handle_message(
      %{
        "event" => "join_room",
        "room_id" => "s-room1",
        "status" => %{user: "0"}
      },
      %{room: nil, turn_token_expiry: previous_expiry}
    )

    receive_and_check_turn_credentials(previous_expiry)

    # previous token is still valid
    Session.handle_message(
      %{
        "event" => "join_room",
        "room_id" => "s-room1",
        "status" => %{user: "0"}
      },
      %{room: nil, turn_token_expiry: previous_expiry}
    )

    receive_and_check_turn_credentials(previous_expiry)
  end

  test "leave explicitly" do
    _client1 =
      create_client("s-room13", fn room, _ ->
        Session.handle_message(
          %{
            "event" => "leave_room",
            "room_id" => "s-room13"
          },
          %{room: room, turn_token_expiry: 0}
        )
      end)

    _client2 =
      create_client("s-room13", fn _, _ ->
        assert_receive {:to_user, %{event: "peer_left", sender_id: _}}, 1000
      end)

    wait_for_breaks(2)
  end

  test "send to peer" do
    client1 =
      create_client("s-room5", fn room, _ ->
        receive do
          peer_id ->
            Session.handle_message(
              %{
                "event" => "send_to_peer",
                "peer_id" => peer_id,
                "data" => %{some: "data"}
              },
              %{room: room, turn_token_expiry: 0}
            )
        end
      end)

    _client2 =
      create_client("s-room5", fn _, own_id ->
        send(client1, own_id)

        assert_receive {:to_user,
                        %{
                          some: "data",
                          sender_id: _
                        }},
                       1000
      end)

    wait_for_breaks(2)
  end

  test "update status" do
    _client1 =
      create_client("s-room6", fn room, _ ->
        Session.handle_message(
          %{
            "event" => "update_status",
            "status" => %{some: "status"}
          },
          %{room: room, turn_token_expiry: 0}
        )
      end)

    _client2 =
      create_client("s-room6", fn _, _ ->
        assert_receive {:to_user,
                        %{
                          event: "peer_updated_status",
                          sender_id: _,
                          status: %{some: "status"}
                        }},
                       1000
      end)

    wait_for_breaks(2)
  end

  test "not possible to use certain events when not in a room" do
    _client1 =
      create_client(fn _, _ ->
        %{room: room} =
          Session.handle_message(
            %{
              "event" => "update_status",
              "status" => %{new: "status"}
            },
            @initial_state
          )

        assert_receive {:to_user, m = %{event: "error"}}
        assert m[:description] == "Action only possible when in a room"

        Session.handle_message(
          %{
            "event" => "send_to_peer",
            "peer_id" => "some_peer",
            "data" => %{some: "data"}
          },
          %{room: room, turn_token_expiry: 0}
        )

        assert_receive {:to_user, m = %{event: "error"}}
        assert m[:description] == "Action only possible when in a room"
      end)

    wait_for_breaks(1)
  end

  test "respond to client ping" do
    Session.handle_message(
      %{
        "event" => "ping"
      },
      @initial_state()
    )

    assert_receive {:to_user, %{event: "pong"}}
  end

  test "return error on unknown message type" do
    Session.handle_message(
      %{
        "event" => "unknown"
      },
      @initial_state
    )

    assert_receive {:to_user, %{event: "error"}}
  end

  defp create_client(room_id \\ nil, leave_after_finish \\ false, fun) do
    host = self()

    pid =
      spawn_link(fn ->
        {room, own_id} =
          case room_id do
            nil ->
              send(host, :start)
              {nil, ""}

            room_id ->
              join_room(room_id, host)
          end

        fun.(room, own_id)
        send(host, :break)
        unless leave_after_finish, do: :timer.sleep(:infinity)
      end)

    assert_receive :start
    pid
  end

  defp join_room(room_id, host) do
    %{room: room} =
      Session.handle_message(
        %{
          "event" => "join_room",
          "room_id" => room_id,
          "status" => %{local: "status"}
        },
        @initial_state
      )

    if host, do: send(host, :start)
    # joined_room
    assert_receive {:to_user, m}, 1000
    # wait for second peer
    if length(m[:peers]) == 0, do: assert_receive({:to_user, %{event: "new_peer"}}, 1000)
    {room, m[:own_id]}
  end
end

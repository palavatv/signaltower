defmodule SignalTower.RoomMember do
  defstruct peer_id: nil, pid: nil, status: nil

  defimpl Poison.Encoder do
    def encode(member, options) do
      member
      |> Map.from_struct
      |> Map.delete(:pid)
      |> Poison.Encoder.Map.encode(options)
    end
  end
end

defmodule SignalTower.Room do
  alias SignalTower.RoomSupervisor
  alias SignalTower.RoomMember
  alias SignalTower.RoomMembership
  alias SignalTower.Stats
  use GenServer

  ## API ##

  def start_link(room_id) do
    name = "room_#{room_id}" |> String.to_atom
    GenServer.start_link(__MODULE__, room_id, name: name)
  end
  
  def join_and_monitor(room_id, status) do
    room_pid = RoomSupervisor.get_room(room_id)
    Process.monitor(room_pid)
    own_id = GenServer.call(room_pid, {:join, self(), status})
    %RoomMembership{id: room_id, pid: room_pid, own_id: own_id, own_status: status}
  end

  ## Callbacks ##

  def init(room_id) do
    GenServer.cast Stats, :count_room
    {:ok, {room_id, %{}}}
  end

  def handle_call {:join, pid, status}, _, {room_id,members} do
    GenServer.cast Stats, :count_user

    Process.monitor(pid)
    peer_id = get_next_id(members)
    send_joined_room(pid, peer_id, members)
    send_new_peer(members, peer_id, status)

    new_member = %RoomMember{peer_id: peer_id, pid: pid, status: status}
    {:reply, peer_id, {room_id, Map.put(members, peer_id, new_member)}}
  end

  defp get_next_id(members) do
    case Map.size(members) do
      0 -> "0"
      _ ->
        ((members |> Map.keys() |> Stream.map(&String.to_integer/1) |> Enum.max()) + 1)
        |> Integer.to_string()
    end
  end

  def handle_cast {:send_to_peer, peer_id, msg, sender_id}, state = {_,members} do
    if members[sender_id] && members[peer_id] do
      send members[peer_id].pid, {:to_user, Map.put(msg, :sender_id, sender_id)}
    end
    {:noreply, state}
  end

  def handle_cast {:update_status, sender_id, status}, state = {_,members} do
    if members[sender_id] do
      update_status = %{
        event: "peer_updated_status",
        sender_id: sender_id,
        status: status
      }

      Map.delete(members, sender_id)
      |> send_to_all(update_status)
    end

    {:noreply, state}
  end

  def handle_cast {:leave, peer_id}, state do
    leave(peer_id, state)
  end

  # invoked when a user session exits
  def handle_info {:DOWN, _ref, _, pid, _}, state = {_,members} do
    members
    |> Enum.find(fn {_,member} -> pid == member.pid end)
    |> case do
      {id,_} -> leave(id, state)
      _ -> {:noreply, state}
    end
  end

  defp leave(peer_id, state = {room_id,members}) do
    if members[peer_id] do
      next_members = Map.delete(members, peer_id)
      if Map.size(next_members) > 0 do
        send_peer_left(next_members, peer_id)
        {:noreply, {room_id, next_members}}
      else
        {:stop, :normal, {room_id, next_members}}
      end
    else
      {:noreply, state}
    end
  end

  defp send_to_all(members, msg) do
    members |> Enum.each(fn({_,member}) ->
      send(member.pid, {:to_user, msg})
    end)
  end

  defp send_joined_room(pid, peer_id, members) do
    response_for_joined_peer = %{
      event: "joined_room",
      own_id: peer_id,
      peers: members |> Map.values(),
    }

    send pid, {:to_user, response_for_joined_peer}
  end

  defp send_new_peer(members, peer_id, status) do
    response_for_other_peers = %{
      event: "new_peer",
      peer_id: peer_id,
      status: status,
    }

    send_to_all(members, response_for_other_peers)
  end

  defp send_peer_left(members, peer_id) do
    leave_msg = %{
      event: "peer_left",
      sender_id: peer_id
    }
    send_to_all(members, leave_msg)
  end
end

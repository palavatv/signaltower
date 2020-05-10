defmodule SignalTower.Room do
  use GenServer, restart: :transient

  alias SignalTower.PrometheusStats
  alias SignalTower.Room
  alias SignalTower.Room.{Member, Membership, Supervisor}
  alias SignalTower.Stats

  ## API ##

  def start_link(room_id) do
    name = "room_#{room_id}" |> String.to_atom()
    GenServer.start_link(__MODULE__, room_id, name: name)
  end

  def create(room_id) do
    case DynamicSupervisor.start_child(Supervisor, {Room, [room_id]}) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  def join_and_monitor(room_id, status) do
    room_pid = create(room_id)
    Process.monitor(room_pid)
    own_id = GenServer.call(room_pid, {:join, self(), status})
    %Membership{id: room_id, pid: room_pid, own_id: own_id, own_status: status}
  end

  ## Callbacks ##

  def init(room_id) do
    GenServer.cast(Stats, {:room_created, self()})
    SignalTower.PrometheusStats.room_created()
    {:ok, {room_id, %{}}}
  end

  def handle_call({:join, pid, status}, _, {room_id, members}) do
    GenServer.cast(Stats, {:update_room_peak, self(), map_size(members) + 1})

    Process.monitor(pid)
    peer_id = UUID.uuid1()
    send_joined_room(pid, peer_id, members)
    send_new_peer(members, peer_id, status)
    PrometheusStats.join()

    new_member = %Member{peer_id: peer_id, pid: pid, status: status}
    {:reply, peer_id, {room_id, Map.put(members, peer_id, new_member)}}
  end

  def handle_call({:leave, peer_id}, _, state) do
    case leave(peer_id, state) do
      {:ok, state} ->
        {:reply, :ok, state}

      {:stop, state} ->
        {:stop, :normal, :ok, state}

      {:error, state} ->
        {:reply, :error, state}
    end
  end

  def handle_cast({:send_to_peer, peer_id, msg, sender_id}, state = {_, members}) do
    if members[sender_id] && members[peer_id] do
      send(members[peer_id].pid, {:to_user, Map.put(msg, :sender_id, sender_id)})
    end

    {:noreply, state}
  end

  def handle_cast({:update_status, sender_id, status}, state = {_, members}) do
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

  # invoked when a user session exits
  def handle_info({:DOWN, _ref, _, pid, _}, state = {_, members}) do
    members
    |> Enum.find(fn {_, member} -> pid == member.pid end)
    |> case do
      {id, _} ->
        case leave(id, state) do
          {:ok, state} -> {:noreply, state}
          {:error, state} -> {:noreply, state}
          {:stop, state} -> {:stop, :normal, state}
        end

      _ ->
        {:noreply, state}
    end
  end

  defp leave(peer_id, state = {room_id, members}) do
    if members[peer_id] do
      PrometheusStats.leave()
      next_members = Map.delete(members, peer_id)

      if map_size(next_members) > 0 do
        send_peer_left(next_members, peer_id)
        {:ok, {room_id, next_members}}
      else
        SignalTower.PrometheusStats.room_closed()
        {:stop, {room_id, next_members}}
      end
    else
      {:error, state}
    end
  end

  defp send_to_all(members, msg) do
    members
    |> Enum.each(fn {_, member} ->
      send(member.pid, {:to_user, msg})
    end)
  end

  defp send_joined_room(pid, peer_id, members) do
    response_for_joined_peer = %{
      event: "joined_room",
      own_id: peer_id,
      peers: members |> Map.values()
    }

    send(pid, {:to_user, response_for_joined_peer})
  end

  defp send_new_peer(members, peer_id, status) do
    response_for_other_peers = %{
      event: "new_peer",
      peer_id: peer_id,
      status: status
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

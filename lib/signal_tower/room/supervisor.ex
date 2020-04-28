defmodule SignalTower.Room.Supervisor do
  use Supervisor

  alias SignalTower.Room

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def create_room(room_id) do
    case Supervisor.start_child(__MODULE__, [room_id]) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  def init(:ok) do
    children = [
      worker(Room, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end

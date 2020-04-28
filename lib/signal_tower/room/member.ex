defmodule SignalTower.Room.Member do
  defstruct peer_id: nil,
            pid: nil,
            status: nil

  defimpl Poison.Encoder do
    def encode(member, options) do
      member
      |> Map.from_struct()
      |> Map.delete(:pid)
      |> Poison.Encoder.Map.encode(options)
    end
  end
end

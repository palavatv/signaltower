defmodule SignalTower.Stats.RoomSession do
  defstruct pid: nil,
            create_time: DateTime.utc_now(),
            peak_time: DateTime.utc_now(),
            peak_user_count: 0
end

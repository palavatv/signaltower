defmodule SignalTower.Stats.Prometheus do
  use Prometheus.Metric

  @counter [
    name: :palava_joined_room_total,
    labels: [],
    help: "Number of peers joined a room"
  ]

  @counter [
    name: :palava_leave_room_total,
    labels: [],
    help: "Number of peers left a room"
  ]

  def reset() do
    Counter.reset(name: :palava_joined_room_total)
    Counter.reset(name: :palava_leave_room_total)
  end

  def join() do
    Counter.inc(name: :palava_joined_room_total)
  end

  def leave() do
    Counter.inc(name: :palava_leave_room_total)
  end

  def to_string() do
    Prometheus.Format.Text.format()
  end
end

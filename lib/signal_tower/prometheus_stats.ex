defmodule SignalTower.PrometheusStats do
  use Prometheus.Metric
  @counter [name: :palava_room_created_total, labels: [], help: "Number of rooms created"]
  @counter [name: :palava_room_closed_total, labels: [], help: "Number of rooms closed"]
  @counter [name: :palava_joined_room_total, labels: [], help: "Number of peers joined a room"]
  @counter [name: :palava_leave_room_total, labels: [], help: "Number of peers left a room"]

  def reset() do
    Counter.reset(name: :palava_room_created_total)
    Counter.reset(name: :palava_room_closed_total)
    Counter.reset(name: :palava_joined_room_total)
    Counter.reset(name: :palava_leave_room_total)
  end

  def room_created() do
    Counter.inc(name: :palava_room_created_total)
  end

  def room_closed() do
    Counter.inc(name: :palava_room_closed_total)
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

defmodule SignalTower.PrometheusStats do
  use Prometheus.Metric

  @counter [name: :palava_room_created_total, labels: [], help: "Number of rooms created"]
  @counter [name: :palava_room_closed_total, labels: [], help: "Number of rooms closed"]
  @counter [name: :palava_joined_room_total, labels: [], help: "Number of peers joined a room"]
  @counter [name: :palava_leave_room_total, labels: [], help: "Number of peers left a room"]
  @histogram [
    name: :palava_duration_room_milliseconds,
    labels: [],
    # Creates 20 buckets {1000, 2000, 4000, 8000, 16000, ...}
    buckets: Prometheus.Buckets.new({:exponential, 1000, 2, 20}),
    help: "Room duration in milliseconds"
  ]
  @histogram [
    name: :palava_room_peak_users_total,
    labels: [],
    buckets: Prometheus.Buckets.new({:linear, 1, 1, 10}),
    help: "Room peak user count"
  ]

  def reset() do
    Counter.reset(name: :palava_room_created_total)
    Counter.reset(name: :palava_room_closed_total)
    Counter.reset(name: :palava_joined_room_total)
    Counter.reset(name: :palava_leave_room_total)
    Histogram.reset(name: :palava_duration_room_milliseconds)
    Histogram.reset(name: :palava_room_peak_users_total)
  end

  def room_created() do
    Counter.inc(name: :palava_room_created_total)
  end

  def room_closed(duration, peak_user_count) do
    Counter.inc(name: :palava_room_closed_total)

    Histogram.observe(
      [name: :palava_duration_room_milliseconds, labels: []],
      duration * 1_000_000
    )

    Histogram.observe([name: :palava_room_peak_users_total, labels: []], peak_user_count)
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

defmodule SignalTower.PrometheusStats do
  use Prometheus.Metric
  @counter [name: :palava_joined_room_total, labels: [], help: "Number of peers joined a room"]

  @counter [name: :palava_leave_room_total, labels: [], help: "Number of peers left a room"]

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

defmodule SignalTower.PrometheusHTTPHandler do
  def init(req, _state) do
    headers = :cowboy_req.headers(req)
    body = SignalTower.PrometheusStats.to_string()

    reply = :cowboy_req.reply(200, headers, body, req)
    {:ok, reply, :no_state}
  end

  def terminate(_reason, _request, _state), do: :ok
end

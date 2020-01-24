defmodule SignalTower.PrometheusHTTPHandler do
  def init(req, _state) do
    headers = :cowboy_req.headers(req)
    body = SignalTower.Stats.Prometheus.to_string()

    reply = :cowboy_req.reply(200, headers, body, req)
    {:ok, reply, :no_state}
  end

  def terminate(_reason, _request, _state), do: :ok
end

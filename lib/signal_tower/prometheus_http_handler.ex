defmodule SignalTower.PrometheusHTTPHandler do
  @behaviour :cowboy_handler

  @impl :cowboy_handler
  def init(req, _state) do
    headers = :cowboy_req.headers(req)
    body = SignalTower.PrometheusStats.to_string()

    IO.inspect(:cowboy_req.header("Authorization", req))

    reply = :cowboy_req.reply(200, headers, body, req)
    {:ok, reply, :no_state}
  end

  @impl :cowboy_handler
  def terminate(_reason, _request, _state), do: :ok
end

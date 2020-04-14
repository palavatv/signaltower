defmodule SignalTower.WebsocketHandler do
  @behaviour :cowboy_websocket

  require Logger
  alias SignalTower.Session

  def init(req, _state) do
    {:cowboy_websocket, req, nil, %{idle_timeout: 24 * 60 * 60 * 1000}}
  end

  def websocket_init(state) do
    Session.init()
    {:ok, state}
  end

  def websocket_handle({:text, msg}, room) do
    case Poison.decode(msg) do
      {:ok, parsed_msg} ->
        {:ok, Session.handle_message(parsed_msg, room)}

      _ ->
        answer = Poison.encode!(%{event: "error", description: "invalid json", received_msg: msg})
        {:reply, {:text, answer}, room}
    end
  end

  def websocket_handle(msg, state) do
    Logger.warn("Unknown message: #{inspect(msg)}")
    {:ok, state}
  end

  def websocket_info({:DOWN, _, _, pid, status}, room) do
    {:ok, Session.handle_exit_message(pid, room, status)}
  end

  def websocket_info({:timeout, _ref, msg}, state) do
    Logger.debug("WebSocket timeout: #{inspect(msg)}")
    {:reply, {:text, "{\"event\": \"error\", \"message\": \"WebSocket timeout: #{msg}\"}"}, state}
  end

  def websocket_info({:internal_error, msg}, state) do
    Logger.warn("cowboy error: #{inspect(msg)}")
    # {:ok, reply} = Palava.handle_server_error(msg)
    {:reply, {:text, "{\"event\": \"error\", \"message\": \"Internal Error: #{msg}\"}"}, state}
  end

  def websocket_info(:kill, state) do
    {:shutdown, state}
  end

  def websocket_info({:to_user, msg}, state) do
    {:reply, {:text, internal_to_json(msg)}, state}
  end

  defp internal_to_json(msg) do
    case Poison.encode(msg) do
      {:ok, msg_json} ->
        msg_json

      _ ->
        Logger.error(
          "Sending message: Could not transform internal object to JSON: #{inspect(msg)}"
        )

        error_msg = Poison.encode!(%{event: "error", message: "internal_server_error"})
        error_msg
    end
  end

  def websocket_terminate(_reason, _state) do
    :ok
  end
end

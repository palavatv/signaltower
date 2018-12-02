defmodule SignalTower.WebsocketHandler do
  @behaviour :cowboy_websocket_handler

  require Logger
  alias SignalTower.Session

  def init({:tcp, :http}, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def websocket_init(_transport_name, req, _opts) do
    Session.init()
    {:ok, req, nil}
  end

  def websocket_handle({:text, msg}, req, room) do
    case Poison.decode(msg) do
      {:ok, parsed_msg} ->
        {:ok, req, Session.handle_message(parsed_msg, room)}
      _ ->
        answer = Poison.encode!(%{event: "error", description: "invalid json", received_msg: msg})
        {:reply, {:text, answer}, req, room}
    end
  end

  def websocket_handle(msg, req, state) do
    Logger.warn "Unknown message: #{inspect(msg)}"
    {:ok, req, state}
  end

  def websocket_info({:DOWN,_,_,pid,status}, req, room) do
    {:ok, req, Session.handle_exit_message(pid, room, status)}
  end

  def websocket_info({:timeout, _ref, msg}, req, state) do
    Logger.debug "WebSocket timeout: #{inspect(msg)}"
    {:reply, {:text, "{\"event\": \"error\", \"message\": \"WebSocket timeout: #{msg}\"}"}, req, state}
  end

  def websocket_info({:internal_error, msg}, req, state) do
    Logger.warn "cowboy error: #{inspect(msg)}"
    #{:ok, reply} = Palava.handle_server_error(msg)
    {:reply, {:text, "{\"event\": \"error\", \"message\": \"Internal Error: #{msg}\"}"}, req, state}
  end

  def websocket_info(:kill, req, state) do
    {:shutdown, req, state}
  end

  def websocket_info({:to_user, msg}, req, state) do
    {:reply, {:text, internal_to_json(msg)}, req, state}
  end

  defp internal_to_json(msg) do
    case Poison.encode(msg) do
      {:ok, msg_json} ->
        msg_json
      _ ->
        Logger.error "Sending message: Could not transform internal object to JSON: #{inspect(msg)}"
        error_msg = Poison.encode! %{event: "error", message: "internal_server_error"}
        error_msg
    end
  end

  def websocket_terminate(_reason, _req, _state) do
    Session.destroy()
    :ok
  end
end

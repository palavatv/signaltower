defmodule SignalTower.WebsocketHandler do
  @behaviour :cowboy_websocket

  require Logger
  alias SignalTower.Session

  @impl :cowboy_websocket
  def init(req, _state) do
    {:cowboy_websocket, req, nil, %{idle_timeout: 24 * 60 * 60 * 1000}}
  end

  @impl :cowboy_websocket
  def websocket_init(state) do
    Session.init()
    {:ok, state}
  end

  @impl :cowboy_websocket
  def websocket_handle({:text, msg}, room) do
    case Poison.decode(msg) do
      {:ok, parsed_msg} ->
        {:ok, Session.handle_message(parsed_msg, room)}

      _ ->
        answer = Poison.encode!(%{event: "error", description: "invalid json", received_msg: msg})
        {:reply, {:text, answer}, room}
    end
  end

  @impl :cowboy_websocket
  def websocket_handle(msg, state) do
    Logger.warn("Unknown handle message: #{inspect(msg)}")
    {:ok, state}
  end

  @impl :cowboy_websocket
  def websocket_info({:DOWN, _, _, pid, status}, room) do
    {:ok, Session.handle_exit_message(pid, room, status)}
  end

  @impl :cowboy_websocket
  def websocket_info({:to_user, msg}, state) do
    {:reply, {:text, internal_to_json(msg)}, state}
  end

  @impl :cowboy_websocket
  def websocket_info(msg, state) do
    Logger.warn("Unknown info message: #{inspect(msg)}")
    {:ok, state}
  end

  defp internal_to_json(msg) do
    case Poison.encode(msg) do
      {:ok, msg_json} ->
        msg_json

      _ ->
        Logger.error(
          "Sending message: Could not transform internal object to JSON: #{inspect(msg)}"
        )

        Poison.encode!(%{event: "error", message: "internal_server_error"})
    end
  end

  @impl :cowboy_websocket
  def terminate(reason, _partialreq, _room) do
    case reason do
      {:error, error} ->
        Logger.warn("websocket error: #{error}")

      {:crash, class, error} ->
        Logger.warn("websocket crash. class: #{class}, reason: #{error}")

      _ ->
        :ok
    end

    :ok
  end
end

defmodule SignalTower.WebsocketHandler do
  @behaviour :cowboy_websocket

  require Logger
  alias SignalTower.Session

  @impl :cowboy_websocket
  def init(req, _state) do
    {:cowboy_websocket, req, nil, %{idle_timeout: :timer.seconds(30)}}
  end

  @impl :cowboy_websocket
  def websocket_init(state) do
    Session.init()
    :timer.send_interval(:timer.seconds(5), :send_ping)
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
  def websocket_handle({:ping, _message}, state) do
    # ignore, cowboy sends pong message automatically
    {:ok, state}
  end

  @impl :cowboy_websocket
  def websocket_handle(:pong, state) do
    # ignore, these should come in every 15s if the websocket connection is alive
    {:ok, state}
  end

  @impl :cowboy_websocket
  def websocket_handle({:pong, _message}, state) do
    # ignore, these should come in every 15s if the websocket connection is alive
    {:ok, state}
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
  def websocket_info(:send_ping, status) do
    {:reply, {:ping, "server ping"}, status}
  end

  @impl :cowboy_websocket
  def websocket_info({:to_user, msg}, state) do
    {:reply, {:text, internal_to_json(msg)}, state}
  end

  @impl :cowboy_websocket
  def websocket_info(:shutdown, state) do
    {:reply, {:text, internal_to_json(%{event: "shutdown"})}, state}
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
  def terminate(reason, req, _room) do
    case reason do
      {:error, error} ->
        Logger.warn("websocket error: #{error}, request: #{inspect(req)}")

      {:crash, class, error} ->
        Logger.warn(
          "websocket crash. class: #{class}, reason: #{error}, request: #{inspect(req)}"
        )

      _ ->
        :ok
    end

    :ok
  end
end

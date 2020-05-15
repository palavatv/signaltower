defmodule SignalTower do
  use Application
  require Logger

  import Supervisor.Spec, warn: false

  alias SignalTower.{WebsocketHandler, PrometheusHTTPHandler, Room, Stats}

  def start(_type, _args) do
    start_cowboy()
    |> start_supervisor()
  end

  def stop(_state) do
    :ok
  end

  defp start_cowboy() do
    {port, _} = Integer.parse(System.get_env("SIGNALTOWER_PORT") || "4233")

    dispatch =
      :cowboy_router.compile([
        {"localhost",
         [
           {"/", WebsocketHandler, []},
           {"/metrics", PrometheusHTTPHandler, []}
         ]},
        {:_, [{"/", WebsocketHandler, []}]}
      ])

    {port, dispatch}
  end

  defp start_supervisor({port, dispatch}) do
    children = [
      {DynamicSupervisor, name: Room.Supervisor, strategy: :one_for_one},
      {Stats, []},
      %{
        id: :cowboy,
        start: {:cowboy, :start_clear, [:http, [port: port], %{env: %{dispatch: dispatch}}]}
      }
    ]

    ret = Supervisor.start_link(children, strategy: :one_for_one)
    Logger.info("SignalTower started")
    ret
  end
end

defmodule SignalTower do
  use Application

  import Supervisor.Spec, warn: false

  alias SignalTower.{WebsocketHandler, PrometheusHTTPHandler, Room, Stats}

  @default_log_file "room-stats.csv"

  def start(_type, _args) do
    start_cowboy()
    |> start_supervisor()
  end

  def stop(_state) do
    :ok
  end

  defp start_cowboy() do
    {port, _} = Integer.parse(System.get_env("PALAVA_RTC_ADDRESS") || "4233")

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
      supervisor(Room.Supervisor, []),
      worker(Stats, [log_file()]),
      worker(:cowboy, [:http, [port: port], %{env: %{dispatch: dispatch}}], function: :start_clear)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp log_file do
    file = System.get_env("PALAVA_STATS_FILE")
    if file && String.trim(file) != "", do: file, else: @default_log_file
  end
end

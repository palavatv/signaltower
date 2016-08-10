defmodule SignalTower do
  @behaviour :application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    start_supervisor()
    start_cowboy()
  end

  def stop(_state) do
    :ok
  end

  defp start_cowboy() do
    {port, _} = Integer.parse(System.get_env("PALAVA_RTC_ADDRESS") || "4233")

    dispatch = :cowboy_router.compile([
      {:_, [{"/", SignalTower.WebsocketHandler, []}]} # TODO check [] if removable
    ])

    {:ok, _} = :cowboy.start_http(:http, 100, [{:port, port}], [{:env, [{:dispatch, dispatch}]}])
  end

  defp start_supervisor() do
    SignalTower.Supervisor.start_link(%{})
  end
end

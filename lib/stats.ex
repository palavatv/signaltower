defmodule SignalTower.Stats do
  use GenServer

  @interval 60*60*1000

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    :collectd.add_server(7)
    get_counts() |> report()
    
    Process.send_after(self(), :report, @interval)
    {:ok, :ok}
  end

  defp get_counts() do
    Process.registered()
    |> Stream.map(&inspect/1)
    |> Enum.reduce({0,0}, fn(process, {rooms, users}) ->
      cond do
        String.match?(process, ~r/^user_/) ->
          {rooms, users+1}
        String.match?(process, ~r/^room_/) ->
          {rooms+1, users}
        true ->
          {rooms, users}
      end
    end)
  end

  defp report({rooms, users}) do
    :collectd.set_gauge(:users1, :users2, [rooms])
    :collectd.set_gauge(:users1, :users2, [users])
  end

  def handle_cast :report, _ do
    get_counts() |> report()
    Process.send_after(self(), :report, @interval)
    {:noreply, :ok}
  end
end

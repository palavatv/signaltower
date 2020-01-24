defmodule PrometheusStatsTest do
  use ExUnit.Case

  alias SignalTower.Stats.Prometheus

  test "should return text formated metrics" do
    assert String.match?(Prometheus.to_string(), ~r/palava_joined_room_total/)
    assert String.match?(Prometheus.to_string(), ~r/palava_leave_room_total/)
  end

  test "should increment on join" do
    Prometheus.reset()
    Prometheus.join()
    metric_map = to_map(Prometheus.to_string())
    assert "1" == metric_map["palava_joined_room_total"]
  end

  test "should increment on leave" do
    Prometheus.reset()
    Prometheus.leave()
    metric_map = to_map(Prometheus.to_string())
    assert "1" == metric_map["palava_leave_room_total"]
  end

  defp to_map(text) do
    text
    |> String.split("\n")
    |> Enum.reject(&String.starts_with?(&1, "#"))
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.split(&1, " "))
    |> Map.new(&List.to_tuple/1)
  end
end

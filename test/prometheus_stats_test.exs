defmodule PrometheusStatsTest do
  use ExUnit.Case, async: false

  test "should return text formated metrics" do
    assert(String.match?(SignalTower.PrometheusStats.to_string, ~r/palava_joined_room_total/))
    assert(String.match?(SignalTower.PrometheusStats.to_string, ~r/palava_leave_room_total/))
  end

  test "should increment on join" do
    SignalTower.PrometheusStats.reset
    SignalTower.PrometheusStats.join
    metricMap = toMap(SignalTower.PrometheusStats.to_string)
    assert("1" == metricMap["palava_joined_room_total"])
  end

  test "should increment on leave" do
    SignalTower.PrometheusStats.reset
    SignalTower.PrometheusStats.leave
    metricMap = toMap(SignalTower.PrometheusStats.to_string)
    assert("1" == metricMap["palava_leave_room_total"])
  end

  defp toMap(text) do
     text
     |> String.split("\n")
     |> Enum.reject(&String.match?(&1, ~r/^#/))
     |> Enum.reject(&String.equivalent?(&1, ""))
     |> Enum.map(&String.split(&1, " "))
     |> Map.new(&List.to_tuple/1)
  end
end

defmodule PrometheusStatsTest do
  use ExUnit.Case

  alias SignalTower.PrometheusStats

  test "should return text formated metrics" do
    assert(String.match?(PrometheusStats.to_string(), ~r/palava_room_created_total/))
    assert(String.match?(PrometheusStats.to_string(), ~r/palava_room_closed_total/))
    assert(String.match?(PrometheusStats.to_string(), ~r/palava_joined_room_total/))
    assert(String.match?(PrometheusStats.to_string(), ~r/palava_leave_room_total/))

    assert(
      String.match?(PrometheusStats.to_string(), ~r/palava_duration_room_milliseconds_bucket/)
    )

    assert(
      String.match?(PrometheusStats.to_string(), ~r/palava_duration_room_milliseconds_count/)
    )

    assert(String.match?(PrometheusStats.to_string(), ~r/palava_duration_room_milliseconds_sum/))
    assert(String.match?(PrometheusStats.to_string(), ~r/palava_room_peak_users_total_bucket/))
    assert(String.match?(PrometheusStats.to_string(), ~r/palava_room_peak_users_total_count/))
    assert(String.match?(PrometheusStats.to_string(), ~r/palava_room_peak_users_total_sum/))
  end

  test "should reset metrics" do
    PrometheusStats.reset()
    metric_map = to_map(PrometheusStats.to_string())
    assert("0" == metric_map["palava_room_created_total"])
    assert("0" == metric_map["palava_room_closed_total"])
    assert("0" == metric_map["palava_joined_room_total"])
    assert("0" == metric_map["palava_leave_room_total"])
    assert("0" == metric_map["palava_duration_room_milliseconds_count"])
    assert("0.0" == metric_map["palava_duration_room_milliseconds_sum"])
    assert("0" == metric_map["palava_room_peak_users_total_count"])
    assert("0" == metric_map["palava_room_peak_users_total_sum"])
  end

  test "should increment on room created" do
    PrometheusStats.reset()
    PrometheusStats.room_created()
    metric_map = to_map(PrometheusStats.to_string())
    assert("1" == metric_map["palava_room_created_total"])
  end

  test "should increment on room closed" do
    PrometheusStats.reset()
    PrometheusStats.room_closed(0, 0)
    metric_map = to_map(PrometheusStats.to_string())
    assert("1" == metric_map["palava_room_closed_total"])
  end

  test "should observe session duratoin on room closed" do
    PrometheusStats.reset()
    PrometheusStats.room_closed(1, 0)
    metric_map = to_map(PrometheusStats.to_string())
    assert("1.0" == metric_map["palava_duration_room_milliseconds_sum"])
  end

  test "should observe peak user count on room closed" do
    PrometheusStats.reset()
    PrometheusStats.room_closed(0, 5)
    metric_map = to_map(PrometheusStats.to_string())
    assert("5" == metric_map["palava_room_peak_users_total_sum"])
  end

  test "should increment on join" do
    PrometheusStats.reset()
    PrometheusStats.join()
    metric_map = to_map(PrometheusStats.to_string())
    assert "1" == metric_map["palava_joined_room_total"]
  end

  test "should increment on leave" do
    PrometheusStats.reset()
    PrometheusStats.leave()
    metric_map = to_map(PrometheusStats.to_string())
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

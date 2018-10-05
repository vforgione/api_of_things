defmodule Aot.Testing.ObservationQueriesTest do
  use Aot.Testing.ObservationsCase

  alias Aot.{
    NetworkActions,
    ObservationActions
  }

  @num_obs 744

  @node_obs 17

  @sensor_obs 28

  @timestamp ~N[2018-09-28 16:35:48]
  @ts_eq 56
  @ts_lt 154
  @ts_le 210
  @ts_ge 590
  @ts_gt 534

  @value 54.51
  @v_eq 1
  @v_lt 517
  @v_le 518
  @v_ge 227
  @v_gt 226

  @polygon %Geo.Polygon{
    srid: 4326,
    coordinates: [[
      {-89, 40},
      {-89, 45},
      {-85, 45},
      {-85, 40},
      {-89, 40}
    ]]
  }

  @point_and_distance {%Geo.Point{srid: 4326, coordinates: {-87.12, 41.43}}, 2000}

  test "include_node/1" do
    ObservationActions.list()
    |> Enum.map(& refute Ecto.assoc_loaded?(&1.node))

    ObservationActions.list(include_node: true)
    |> Enum.map(& assert Ecto.assoc_loaded?(&1.node))
  end

  test "include_sensor/1" do
    ObservationActions.list()
    |> Enum.map(& refute Ecto.assoc_loaded?(&1.sensor))

    ObservationActions.list(include_sensor: true)
    |> Enum.map(& assert Ecto.assoc_loaded?(&1.sensor))
  end

  test "include_networks/1" do
    ObservationActions.list()
    |> Enum.map(& refute Ecto.assoc_loaded?(&1.node))

    ObservationActions.list(include_networks: true)
    |> Enum.map(& assert Ecto.assoc_loaded?(&1.node.networks))
  end

  test "for_network/2", %{network: network} do
    {:ok, net} =
      NetworkActions.create(
        name: "Chicago Complete",
        archive_url: "https://example.com/archive1",
        recent_url: "https://example.com/recent1",
        first_observation: ~N[2018-01-01 00:00:00],
        latest_observation: NaiveDateTime.utc_now()
      )

    obs = ObservationActions.list(for_network: net)
    assert length(obs) == 0

    obs = ObservationActions.list(for_network: network)
    assert length(obs) == @num_obs

  end

  test "for_node/2", %{node: node} do
    obs = ObservationActions.list(for_node: node)
    assert length(obs) == @node_obs
  end

  test "for_sensor/2", %{sensor: sensor} do
    obs = ObservationActions.list(for_sensor: sensor)
    assert length(obs) == @sensor_obs
  end

  describe "timestamp_op/2" do
    test "eq" do
      obs = ObservationActions.list(timestamp_op: {:eq, @timestamp})
      assert length(obs) == @ts_eq
    end

    test "lt" do
      obs = ObservationActions.list(timestamp_op: {:lt, @timestamp})
      assert length(obs) == @ts_lt
    end

    test "le" do
      obs = ObservationActions.list(timestamp_op: {:le, @timestamp})
      assert length(obs) == @ts_le
    end

    test "ge" do
      obs = ObservationActions.list(timestamp_op: {:ge, @timestamp})
      assert length(obs) == @ts_ge
    end

    test "gt" do
      obs = ObservationActions.list(timestamp_op: {:gt, @timestamp})
      assert length(obs) == @ts_gt
    end
  end

  describe "value_op/2" do
    test "eq" do
      obs = ObservationActions.list(value_op: {:eq, @value})
      assert length(obs) == @v_eq
    end

    test "lt" do
      obs = ObservationActions.list(value_op: {:lt, @value})
      assert length(obs) == @v_lt
    end

    test "le" do
      obs = ObservationActions.list(value_op: {:le, @value})
      assert length(obs) == @v_le
    end

    test "ge" do
      obs = ObservationActions.list(value_op: {:ge, @value})
      assert length(obs) == @v_ge
    end

    test "gt" do
      obs = ObservationActions.list(value_op: {:gt, @value})
      assert length(obs) == @v_gt
    end
  end

  test "located_within/2" do
    obs = ObservationActions.list(located_within: %Geo.Polygon{
      srid: 4326,
      coordinates: [[
        {1, 1},
        {1, 2},
        {2, 2},
        {2, 1},
        {1, 1}
      ]]
    })
    assert length(obs) == 0

    obs = ObservationActions.list(located_within: @polygon)
    assert length(obs) == @num_obs
  end

  test "within_distance/2" do
    obs = ObservationActions.list(within_distance: {%Geo.Point{srid: 4326, coordinates: {1, 1}}, 1000})
    assert length(obs) == 0

    obs = ObservationActions.list(within_distance: @point_and_distance)
    assert length(obs) == @num_obs
  end

  test "histogram/2" do
    ObservationActions.list(as_histogram: {0, 100, 10, :node_id})
    |> Enum.each(fn [_node_id, counts] ->
      assert length(counts) == 12
      Enum.each(counts, & &1 >= 0)
    end)
  end

  describe "value_agg/2" do
    test "first" do
      [first_obs] = ObservationActions.list(value_agg: {:first, nil})
      assert is_float(first_obs)
    end

    test "last" do
      [last_obs] = ObservationActions.list(value_agg: {:last, nil})
      assert is_float(last_obs)
    end

    test "count" do
      ObservationActions.list(value_agg: {:count, :node_id})
      |> Enum.each(fn [_node_id, count] -> assert count >= 0 end)
    end

    test "min" do
      ObservationActions.list(value_agg: {:min, :node_id})
      |> Enum.each(fn [_node_id, min] -> assert is_float(min) end)
    end

    test "max" do
      ObservationActions.list(value_agg: {:max, :node_id})
      |> Enum.each(fn [_node_id, max] -> assert is_float(max) end)
    end

    test "avg" do
      ObservationActions.list(value_agg: {:avg, :node_id})
      |> Enum.each(fn [_node_id, avg] -> assert is_float(avg) end)
    end

    test "sum" do
      ObservationActions.list(value_agg: {:sum, :node_id})
      |> Enum.each(fn [_node_id, sum] -> assert is_float(sum) end)
    end

    test "stddev" do
      ObservationActions.list(value_agg: {:stddev, :node_id})
      |> Enum.each(fn [_node_id, stddev] -> assert is_float(stddev) end)
    end

    test "variance" do
      ObservationActions.list(value_agg: {:variance, :node_id})
      |> Enum.each(fn [_node_id, variance] -> assert is_float(variance) end)
    end

    test "percentile (.5 ~ median)" do
      ObservationActions.list(value_agg: {:percentile, {0.5, :node_id}})
      |> Enum.each(fn [_node_id, median] -> assert is_float(median) end)
    end
  end

  describe "time_bucket/2" do
    test "count" do
      ObservationActions.list(as_time_buckets: {:count, "1 seconds"})
      |> Enum.each(fn [{_ymd, _hms}, count] -> assert count >= 0 end)
    end

    test "min" do
      ObservationActions.list(as_time_buckets: {:min, "1 seconds"})
      |> Enum.each(fn [{_ymd, _hms}, min] -> assert is_float(min) end)
    end

    test "max" do
      ObservationActions.list(as_time_buckets: {:max, "1 seconds"})
      |> Enum.each(fn [{_ymd, _hms}, max] -> assert is_float(max) end)
    end

    test "avg" do
      ObservationActions.list(as_time_buckets: {:avg, "1 seconds"})
      |> Enum.each(fn [{_ymd, _hms}, avg] -> assert is_float(avg) end)
    end

    test "sum" do
      ObservationActions.list(as_time_buckets: {:sum, "1 seconds"})
      |> Enum.each(fn [{_ymd, _hms}, sum] -> assert is_float(sum) end)
    end

    test "stddev" do
      ObservationActions.list(as_time_buckets: {:stddev, "1 seconds"})
      |> Enum.each(fn [{_ymd, _hms}, stddev] -> assert is_float(stddev) end)
    end

    test "variance" do
      ObservationActions.list(as_time_buckets: {:variance, "1 seconds"})
      |> Enum.each(fn [{_ymd, _hms}, variance] -> assert is_float(variance) end)
    end

    test "percentile (.5 ~ median)" do
      ObservationActions.list(as_time_buckets: {:percentile, {0.5, "1 seconds"}})
      |> Enum.each(fn [{_ymd, _hms}, min] -> assert is_float(min) end)
    end
  end

  test "handle_opts/2" do
    # i want the average temperature by node
    # from nodes within 2 km of my location
    # and i know a few of these nodes report
    # bad data, so i'm setting an upper bound
    ObservationActions.list(
      for_sensor: "metsense.bmp180.temperature",
      within_distance: @point_and_distance,
      value_agg: {:avg, :node_id},
      value_op: {:lt, 100}
    )
    |> Enum.each(fn [_node_id, avg] -> assert avg < 100 end)
  end
end
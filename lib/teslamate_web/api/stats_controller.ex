defmodule TeslaMateWeb.Api.StatsController do
  use TeslaMateWeb, :controller

  alias TeslaMate.Log
  alias TeslaMateWeb.Api.Views.StatsJSON

  action_fallback TeslaMateWeb.Api.FallbackController

  defp parse_date_params(params) do
    from =
      case Map.get(params, "from") do
        nil -> nil
        str -> parse_datetime(str)
      end

    to =
      case Map.get(params, "to") do
        nil -> nil
        str -> parse_datetime(str)
      end

    {from, to}
  end

  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ ->
        case NaiveDateTime.from_iso8601(str) do
          {:ok, ndt} -> ndt
          _ -> nil
        end
    end
  end

  defp parse_int(nil, default), do: default
  defp parse_int(str, _default) when is_binary(str), do: String.to_integer(str)
  defp parse_int(val, _default) when is_integer(val), do: val

  # GET /cars/:car_id/stats/battery_health
  def battery_health(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    data = Log.stats_battery_health(car_id, from: from, to: to)
    json(conn, %{data: StatsJSON.battery_health(data)})
  end

  # GET /cars/:car_id/stats/projected_range
  def projected_range(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    data = Log.stats_projected_range(car_id, from: from, to: to)
    json(conn, %{data: StatsJSON.projected_range(data)})
  end

  # GET /cars/:car_id/stats/charge_level
  def charge_level(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    data = Log.stats_charge_level(car_id, from: from, to: to)
    json(conn, %{data: StatsJSON.charge_level(data)})
  end

  # GET /cars/:car_id/stats/vampire_drain
  def vampire_drain(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    data = Log.stats_vampire_drain(car_id, from: from, to: to)
    json(conn, %{data: StatsJSON.vampire_drain(data)})
  end

  # GET /cars/:car_id/stats/drives
  def drives(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    bucket = Map.get(params, "bucket", "month")
    data = Log.stats_drives(car_id, from: from, to: to, bucket: bucket)
    json(conn, %{data: StatsJSON.drives(data)})
  end

  # GET /cars/:car_id/stats/efficiency
  def efficiency(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    data = Log.stats_efficiency(car_id, from: from, to: to)
    json(conn, %{data: StatsJSON.efficiency(data)})
  end

  # GET /cars/:car_id/stats/mileage
  def mileage(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    bucket = Map.get(params, "bucket", "month")
    data = Log.stats_mileage(car_id, from: from, to: to, bucket: bucket)
    json(conn, %{data: StatsJSON.mileage(data)})
  end

  # GET /cars/:car_id/stats/visited/heatmap
  def visited_heatmap(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    data = Log.stats_visited_heatmap(car_id, from: from, to: to)
    json(conn, %{data: StatsJSON.visited_heatmap(data)})
  end

  # GET /cars/:car_id/stats/visited/routes
  def visited_routes(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    limit = parse_int(Map.get(params, "limit"), 50)
    data = Log.stats_visited_routes(car_id, from: from, to: to, limit: limit)
    json(conn, %{data: StatsJSON.visited_routes(data)})
  end

  # GET /cars/:car_id/stats/visited/places
  def visited_places(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    data = Log.stats_visited_places(car_id, from: from, to: to)
    json(conn, %{data: StatsJSON.visited_places(data)})
  end

  # GET /cars/:car_id/stats/charging
  def charging(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    bucket = Map.get(params, "bucket", "month")
    data = Log.stats_charging(car_id, from: from, to: to, bucket: bucket)
    json(conn, %{data: StatsJSON.charging(data)})
  end

  # GET /cars/:car_id/stats/charging/dc_curve
  def dc_curve(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    data = Log.stats_dc_curve(car_id, from: from, to: to)
    json(conn, %{data: StatsJSON.dc_curve(data)})
  end

  # GET /cars/:car_id/states
  def states(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    data = Log.stats_states(car_id, from: from, to: to)
    json(conn, %{data: StatsJSON.states(data)})
  end

  # GET /cars/:car_id/timeline
  def timeline(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    page = parse_int(Map.get(params, "page"), 1)
    per_page = parse_int(Map.get(params, "per_page"), 50)
    data = Log.stats_timeline(car_id, from: from, to: to, page: page, per_page: per_page)
    json(conn, %{data: StatsJSON.timeline(data)})
  end

  # GET /cars/:car_id/updates
  def updates(conn, %{"car_id" => car_id} = params) do
    car_id = String.to_integer(car_id)
    {from, to} = parse_date_params(params)
    data = Log.stats_updates(car_id, from: from, to: to)
    json(conn, %{data: StatsJSON.updates(data)})
  end
end

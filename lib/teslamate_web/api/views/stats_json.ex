defmodule TeslaMateWeb.Api.Views.StatsJSON do
  alias TeslaMate.Locations.{Address, GeoFence}

  def battery_health(data) do
    %{
      current_soh: to_float(data.current_soh),
      total_charges: data[:total_charges] || 0,
      total_energy_added: to_float(data[:total_energy_added]),
      ac_energy_kwh: to_float(data[:ac_energy_kwh]),
      dc_energy_kwh: to_float(data[:dc_energy_kwh]),
      usable_capacity_km: to_float(data[:usable_capacity_km]),
      points:
        Enum.map(data.points, fn p ->
          %{
            date: format_datetime(p.date),
            rated_range_km: to_float(p.rated_range_km),
            battery_level: p.battery_level,
            soh_estimate: to_float(p.soh_estimate)
          }
        end)
    }
  end

  def projected_range(%{points: points}) do
    %{
      points:
        Enum.map(points, fn p ->
          %{
            date: format_datetime(p.date),
            rated_range_km: to_float(p.rated_range_km),
            ideal_range_km: to_float(p.ideal_range_km),
            battery_level: p.battery_level,
            odometer_km: to_float(p[:odometer_km]),
            outside_temp: to_float(p[:outside_temp])
          }
        end)
    }
  end

  def charge_level(%{current: current, points: points}) do
    %{
      current_level: current,
      points:
        Enum.map(points, fn p ->
          %{
            date: format_datetime(p.date),
            battery_level: p.battery_level,
            usable_battery_level: p.usable_battery_level
          }
        end)
    }
  end

  def vampire_drain(%{avg_loss_per_hour: avg, points: points}) do
    %{
      avg_loss_per_hour: to_float(avg),
      points:
        Enum.map(points, fn p ->
          %{
            date: format_datetime(p.date),
            start_date: format_datetime(p[:start_date] || p.date),
            end_date: format_datetime(p[:end_date]),
            start_level: p.start_level,
            end_level: p.end_level,
            duration_hours: to_float(p.duration_hours),
            loss_per_hour: to_float(p.loss_per_hour),
            start_range_km: to_float(p[:start_range_km]),
            end_range_km: to_float(p[:end_range_km]),
            range_diff_km: to_float(p[:range_diff_km]),
            avg_power_watts: to_float(p[:avg_power_watts]),
            standby_percentage: to_float(p[:standby_percentage]),
            outside_temp: to_float(p[:outside_temp])
          }
        end)
    }
  end

  def drives(%{totals: totals, buckets: buckets}) do
    %{
      totals: format_drive_totals(totals),
      buckets:
        Enum.map(buckets, fn b ->
          %{
            period: format_datetime(b.period),
            count: b.count,
            distance_km: to_float(b.distance_km),
            duration_min: b.duration_min,
            energy_kwh: to_float(b.energy_kwh)
          }
        end)
    }
  end

  def efficiency(data) do
    %{
      avg_efficiency: to_float(data.avg_efficiency),
      rated_efficiency: to_float(data[:rated_efficiency]),
      net_consumption_wh_km: to_float(data[:net_consumption_wh_km]),
      temperature_buckets:
        Enum.map(data[:temperature_buckets] || [], fn b ->
          %{
            temp_bucket: to_float(b.temp_bucket),
            count: b.count,
            avg_efficiency: to_float(b.avg_efficiency),
            avg_speed: to_float(b.avg_speed),
            total_distance_km: to_float(b.total_distance_km)
          }
        end),
      points:
        Enum.map(data.points, fn p ->
          %{
            date: format_datetime(p.date),
            distance_km: to_float(p.distance_km),
            energy_kwh: to_float(p.energy_kwh),
            efficiency_wh_km: to_float(p.efficiency_wh_km),
            outside_temp_avg: to_float(p.outside_temp_avg),
            speed_avg: to_float(p.speed_avg)
          }
        end)
    }
  end

  def mileage(%{current_odometer: odometer, buckets: buckets}) do
    %{
      current_odometer_km: to_float(odometer),
      buckets:
        Enum.map(buckets, fn b ->
          %{
            period: format_datetime(b.period),
            distance_km: to_float(b.distance_km),
            cumulative_km: to_float(b.cumulative_km)
          }
        end)
    }
  end

  def visited_heatmap(points) do
    Enum.map(points, fn p ->
      %{
        latitude: to_float(p.latitude),
        longitude: to_float(p.longitude),
        count: p.count
      }
    end)
  end

  def visited_routes(routes) do
    Enum.map(routes, fn r ->
      %{
        drive_id: r.drive_id,
        start_address: format_address(r.start_address),
        end_address: format_address(r.end_address),
        count: r.count,
        total_distance_km: to_float(r.total_distance_km)
      }
    end)
  end

  def visited_places(places) do
    Enum.map(places, fn p ->
      %{
        address: format_address(p.address),
        geofence: format_geofence(p.geofence),
        visit_count: p.visit_count,
        charge_count: p.charge_count,
        latitude: to_float(p.latitude),
        longitude: to_float(p.longitude)
      }
    end)
  end

  def charging(%{totals: totals, buckets: buckets}) do
    %{
      totals: %{
        total_energy_kwh: to_float(totals.total_energy_kwh),
        total_cost: to_float(totals.total_cost),
        total_sessions: totals.total_sessions,
        avg_energy_kwh: to_float(totals.avg_energy_kwh),
        ac_sessions: totals.ac_sessions,
        dc_sessions: totals.dc_sessions,
        ac_energy_kwh: to_float(totals[:ac_energy_kwh]),
        dc_energy_kwh: to_float(totals[:dc_energy_kwh]),
        ac_duration_min: to_float(totals[:ac_duration_min]),
        dc_duration_min: to_float(totals[:dc_duration_min])
      },
      buckets:
        Enum.map(buckets, fn b ->
          %{
            period: format_datetime(b.period),
            energy_kwh: to_float(b.energy_kwh),
            cost: to_float(b.cost),
            sessions: b.sessions,
            ac_energy_kwh: to_float(b.ac_energy_kwh),
            dc_energy_kwh: to_float(b.dc_energy_kwh)
          }
        end)
    }
  end

  def top_charging_stations(stations) do
    Enum.map(stations, fn s ->
      %{
        address_id: s.address_id,
        display_name: s.display_name,
        city: s.city,
        country: s.country,
        latitude: to_float(s.latitude),
        longitude: to_float(s.longitude),
        sessions: s.sessions,
        total_energy_kwh: to_float(s.total_energy_kwh),
        total_cost: to_float(s.total_cost)
      }
    end)
  end

  def dc_curve(points) do
    Enum.map(points, fn p ->
      %{
        battery_level: p.battery_level,
        charger_power: p.charger_power,
        charge_energy_added: to_float(p.charge_energy_added),
        charger_voltage: p.charger_voltage,
        outside_temp: to_float(p.outside_temp)
      }
    end)
  end

  def states(entries) do
    Enum.map(entries, fn s ->
      %{
        state: to_string(s.state),
        start_date: format_datetime(s.start_date),
        end_date: format_datetime(s.end_date),
        duration_min: s.duration_min
      }
    end)
  end

  def timeline(%{entries: entries, page: page, per_page: per_page, total: total}) do
    %{
      entries:
        Enum.map(entries, fn e ->
          base = %{
            type: e.type,
            id: e.id,
            start_date: format_datetime(e.start_date),
            end_date: format_datetime(e.end_date),
            title: e.title,
            subtitle: e.subtitle
          }
          # Add enriched fields if present
          base
          |> maybe_put(:distance_km, to_float(e[:distance_km]))
          |> maybe_put(:energy_kwh, to_float(e[:energy_kwh]))
          |> maybe_put(:energy_added_kwh, to_float(e[:energy_added_kwh]))
          |> maybe_put(:cost, to_float(e[:cost]))
          |> maybe_put(:address, e[:address])
          |> maybe_put(:start_soc, e[:start_soc])
          |> maybe_put(:end_soc, e[:end_soc])
          |> maybe_put(:outside_temp, to_float(e[:outside_temp]))
        end),
      page: page,
      per_page: per_page,
      total: total
    }
  end

  def statistics(%{buckets: buckets}) do
    %{
      buckets:
        Enum.map(buckets, fn b ->
          %{
            period: format_datetime(b.period),
            time_driven_min: b.time_driven_min,
            distance_km: to_float(b.distance_km),
            avg_temp: to_float(b.avg_temp),
            avg_speed: to_float(b.avg_speed),
            efficiency_wh_km: to_float(b.efficiency_wh_km),
            energy_kwh: to_float(b.energy_kwh),
            drives: b.drives,
            charges: b.charges,
            energy_added_kwh: to_float(b.energy_added_kwh),
            total_cost: to_float(b.total_cost),
            cost_per_kwh: to_float(b.cost_per_kwh),
            cost_per_100km: to_float(b.cost_per_100km)
          }
        end)
    }
  end

  def updates(entries) do
    Enum.map(entries, fn u ->
      %{
        version: u.version,
        start_date: format_datetime(u.start_date),
        end_date: format_datetime(u.end_date)
      }
    end)
  end

  defp format_drive_totals(totals) do
    %{
      total_drives: totals.total_drives,
      total_distance_km: to_float(totals.total_distance_km),
      total_duration_min: totals.total_duration_min,
      total_energy_kwh: to_float(totals.total_energy_kwh),
      avg_speed: to_float(totals.avg_speed)
    }
  end

  defp format_address(%Address{} = a) do
    %{id: a.id, display_name: a.display_name, city: a.city, country: a.country}
  end

  defp format_address(%{display_name: name}), do: %{display_name: name}
  defp format_address(_), do: nil

  defp format_geofence(%GeoFence{} = g), do: %{id: g.id, name: g.name}
  defp format_geofence(%{name: name}), do: %{name: name}
  defp format_geofence(_), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp to_float(nil), do: nil
  defp to_float(%Decimal{} = d), do: Decimal.to_float(d)
  defp to_float(v) when is_float(v), do: v
  defp to_float(v) when is_integer(v), do: v / 1
  defp to_float(v), do: v

  defp format_datetime(nil), do: nil
  defp format_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp format_datetime(%NaiveDateTime{} = dt), do: NaiveDateTime.to_iso8601(dt)
  defp format_datetime(v), do: to_string(v)
end

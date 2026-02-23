defmodule TeslaMateWeb.Api.Views.CarJSON do
  alias TeslaMate.Log.Car
  alias TeslaMate.Settings.CarSettings
  alias TeslaMate.Vehicles.Vehicle.Summary

  def car(%Car{} = car) do
    %{
      id: car.id,
      name: car.name,
      vin: car.vin,
      model: car.model,
      trim_badging: car.trim_badging,
      marketing_name: car.marketing_name,
      exterior_color: car.exterior_color,
      wheel_type: car.wheel_type,
      spoiler_type: car.spoiler_type,
      efficiency: car.efficiency
    }
  end

  def car_with_settings(%Car{} = car) do
    base = car(car)

    settings =
      case car.settings do
        %CarSettings{} = s ->
          %{
            suspend_min: s.suspend_min,
            suspend_after_idle_min: s.suspend_after_idle_min,
            req_not_unlocked: s.req_not_unlocked,
            free_supercharging: s.free_supercharging,
            use_streaming_api: s.use_streaming_api
          }

        _ ->
          nil
      end

    Map.put(base, :settings, settings)
  end

  def summary(%Summary{} = s) do
    %{
      display_name: s.display_name,
      state: to_string(s.state),
      since: format_datetime(s.since),
      healthy: s.healthy,
      latitude: to_float(s.latitude),
      longitude: to_float(s.longitude),
      heading: nilify(s.heading),
      battery_level: nilify(s.battery_level),
      usable_battery_level: nilify(s.usable_battery_level),
      charging_state: nilify(s.charging_state),
      ideal_battery_range_km: to_float(s.ideal_battery_range_km),
      est_battery_range_km: to_float(s.est_battery_range_km),
      rated_battery_range_km: to_float(s.rated_battery_range_km),
      charge_energy_added: to_float(s.charge_energy_added),
      charge_limit_soc: nilify(s.charge_limit_soc),
      charge_port_door_open: nilify(s.charge_port_door_open),
      charger_actual_current: nilify(s.charger_actual_current),
      charger_phases: nilify(s.charger_phases),
      charger_power: nilify(s.charger_power),
      charger_voltage: nilify(s.charger_voltage),
      charge_current_request: nilify(s.charge_current_request),
      charge_current_request_max: nilify(s.charge_current_request_max),
      time_to_full_charge: to_float(s.time_to_full_charge),
      scheduled_charging_start_time: format_datetime(s.scheduled_charging_start_time),
      speed: nilify(s.speed),
      power: nilify(s.power),
      shift_state: nilify(s.shift_state),
      outside_temp: to_float(s.outside_temp),
      inside_temp: to_float(s.inside_temp),
      is_climate_on: nilify(s.is_climate_on),
      is_preconditioning: nilify(s.is_preconditioning),
      climate_keeper_mode: nilify(s.climate_keeper_mode),
      odometer: to_float(s.odometer),
      locked: nilify(s.locked),
      sentry_mode: nilify(s.sentry_mode),
      plugged_in: nilify(s.plugged_in),
      windows_open: nilify(s.windows_open),
      doors_open: nilify(s.doors_open),
      trunk_open: nilify(s.trunk_open),
      frunk_open: nilify(s.frunk_open),
      is_user_present: nilify(s.is_user_present),
      elevation: nilify(s.elevation),
      geofence: format_geofence(s.geofence),
      model: s.model,
      trim_badging: s.trim_badging,
      exterior_color: s.exterior_color,
      wheel_type: s.wheel_type,
      spoiler_type: s.spoiler_type,
      version: s.version,
      update_available: nilify(s.update_available),
      update_version: s.update_version,
      tpms_pressure_fl: to_float(s.tpms_pressure_fl),
      tpms_pressure_fr: to_float(s.tpms_pressure_fr),
      tpms_pressure_rl: to_float(s.tpms_pressure_rl),
      tpms_pressure_rr: to_float(s.tpms_pressure_rr),
      active_route_destination: s.active_route_destination,
      active_route_latitude: to_float(s.active_route_latitude),
      active_route_longitude: to_float(s.active_route_longitude),
      active_route_energy_at_arrival: nilify(s.active_route_energy_at_arrival),
      active_route_miles_to_arrival: to_float(s.active_route_miles_to_arrival),
      active_route_minutes_to_arrival: to_float(s.active_route_minutes_to_arrival),
      center_display_state: nilify(s.center_display_state)
    }
  end

  # Convert :unknown atoms and other non-serializable values to nil
  defp nilify(:unknown), do: nil
  defp nilify(v), do: v

  defp to_float(nil), do: nil
  defp to_float(:unknown), do: nil
  defp to_float(%Decimal{} = d), do: Decimal.to_float(d)
  defp to_float(v) when is_float(v), do: v
  defp to_float(v) when is_integer(v), do: v / 1
  defp to_float(v), do: v

  defp format_geofence(%{name: name}), do: name
  defp format_geofence(name) when is_binary(name), do: name
  defp format_geofence(_), do: nil

  defp format_datetime(nil), do: nil
  defp format_datetime(:unknown), do: nil
  defp format_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp format_datetime(%NaiveDateTime{} = dt), do: NaiveDateTime.to_iso8601(dt)
  defp format_datetime(v), do: v
end

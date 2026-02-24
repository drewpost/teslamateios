defmodule TeslaMate.Log do
  @moduledoc """
  The Log context.
  """

  require Logger

  import TeslaMate.CustomExpressions
  import Ecto.Query, warn: false

  alias __MODULE__.{Car, Drive, Update, ChargingProcess, Charge, Position, State}
  alias TeslaMate.{Repo, Locations, Settings}
  alias TeslaMate.Locations.GeoFence
  alias TeslaMate.Settings.{CarSettings, GlobalSettings}

  ## Car

  def list_cars do
    Repo.all(Car)
  end

  def get_car!(id) do
    Repo.get!(Car, id)
  end

  def get_car_by([{_key, nil}]), do: nil
  def get_car_by([{_key, _val}] = opts), do: Repo.get_by(Car, opts)

  def create_car(attrs) do
    %Car{settings: %CarSettings{}}
    |> Car.changeset(attrs)
    |> Repo.insert()
  end

  def create_or_update_car(%Ecto.Changeset{} = changeset) do
    with {:ok, car} <- Repo.insert_or_update(changeset) do
      {:ok, Repo.preload(car, [:settings])}
    end
  end

  def update_car(%Car{} = car, attrs, opts \\ []) do
    with {:ok, car} <- car |> Car.changeset(attrs) |> Repo.update() do
      preloads = Keyword.get(opts, :preload, [])
      {:ok, Repo.preload(car, preloads, force: true)}
    end
  end

  def recalculate_efficiencies(%GlobalSettings{} = settings) do
    for car <- list_cars() do
      {:ok, _car} = recalculate_efficiency(car, settings)
    end

    :ok
  end

  ## API Queries

  def list_drives(car_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20) |> min(100)
    offset = (page - 1) * per_page

    query =
      from d in Drive,
        where: d.car_id == ^car_id and not is_nil(d.end_date),
        order_by: [desc: d.start_date],
        preload: [:start_address, :end_address, :start_geofence, :end_geofence],
        offset: ^offset,
        limit: ^per_page

    query =
      case {Keyword.get(opts, :since), Keyword.get(opts, :until)} do
        {nil, nil} ->
          query

        {since, nil} ->
          from d in query, where: d.start_date >= ^since

        {nil, until_dt} ->
          from d in query, where: d.start_date <= ^until_dt

        {since, until_dt} ->
          from d in query, where: d.start_date >= ^since and d.start_date <= ^until_dt
      end

    count_query =
      from d in Drive, where: d.car_id == ^car_id and not is_nil(d.end_date), select: count()

    total = Repo.one(count_query)
    entries = Repo.all(query)

    %{entries: entries, page: page, per_page: per_page, total: total}
  end

  def get_drive(id) do
    Drive
    |> where(id: ^id)
    |> preload([:start_address, :end_address, :start_geofence, :end_geofence, :car])
    |> Repo.one()
  end

  def get_drive_with_positions(id) do
    case get_drive(id) do
      nil ->
        nil

      drive ->
        positions =
          from(p in Position,
            where: p.drive_id == ^id,
            order_by: [asc: p.date]
          )
          |> Repo.all()

        {drive, positions}
    end
  end

  def list_charging_processes(car_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20) |> min(100)
    offset = (page - 1) * per_page

    query =
      from cp in ChargingProcess,
        where: cp.car_id == ^car_id and not is_nil(cp.end_date),
        order_by: [desc: cp.start_date],
        preload: [:address, :geofence],
        offset: ^offset,
        limit: ^per_page

    query =
      case {Keyword.get(opts, :since), Keyword.get(opts, :until)} do
        {nil, nil} ->
          query

        {since, nil} ->
          from cp in query, where: cp.start_date >= ^since

        {nil, until_dt} ->
          from cp in query, where: cp.start_date <= ^until_dt

        {since, until_dt} ->
          from cp in query, where: cp.start_date >= ^since and cp.start_date <= ^until_dt
      end

    count_query =
      from cp in ChargingProcess,
        where: cp.car_id == ^car_id and not is_nil(cp.end_date),
        select: count()

    total = Repo.one(count_query)
    entries = Repo.all(query)

    %{entries: entries, page: page, per_page: per_page, total: total}
  end

  def get_charging_process_with_charges(id) do
    case Repo.get(ChargingProcess, id) do
      nil ->
        nil

      cp ->
        cp = Repo.preload(cp, [:address, :geofence, :car, :position])

        charges =
          from(c in Charge,
            where: c.charging_process_id == ^id,
            order_by: [asc: c.date]
          )
          |> Repo.all()

        {cp, charges}
    end
  end

  def list_positions(car_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 100) |> min(1000)
    offset = (page - 1) * per_page

    query =
      from p in Position,
        where: p.car_id == ^car_id,
        order_by: [desc: p.date],
        offset: ^offset,
        limit: ^per_page

    query =
      case {Keyword.get(opts, :since), Keyword.get(opts, :until)} do
        {nil, nil} -> query
        {since, nil} -> from p in query, where: p.date >= ^since
        {nil, until_dt} -> from p in query, where: p.date <= ^until_dt
        {since, until_dt} -> from p in query, where: p.date >= ^since and p.date <= ^until_dt
      end

    Repo.all(query)
  end

  def get_car(id) do
    Car
    |> Repo.get(id)
    |> Repo.preload(:settings)
  end

  ## State

  def start_state(%Car{} = car, state, opts \\ []) when not is_nil(state) do
    now = Keyword.get(opts, :date) || DateTime.utc_now()

    case get_current_state(car) do
      %State{state: ^state} = s ->
        {:ok, s}

      %State{} = s ->
        Repo.transaction(fn ->
          with {:ok, _} <- s |> State.changeset(%{end_date: now}) |> Repo.update(),
               {:ok, new_state} <- create_state(car, %{state: state, start_date: now}) do
            new_state
          else
            {:error, reason} -> Repo.rollback(reason)
          end
        end)

      nil ->
        create_state(car, %{state: state, start_date: now})
    end
  end

  def get_current_state(%Car{id: id}) do
    State
    |> where([s], ^id == s.car_id and is_nil(s.end_date))
    |> Repo.one()
  end

  def create_current_state(%Car{id: id} = car) do
    query =
      from s in State,
        where: s.car_id == ^id,
        order_by: [desc: s.start_date],
        limit: 1

    with nil <- get_current_state(car),
         %State{} = state <- Repo.one(query),
         {:ok, _} <- state |> State.changeset(%{end_date: nil}) |> Repo.update() do
      :ok
    else
      {:error, reason} -> {:error, reason}
      _ -> :ok
    end
  end

  def complete_current_state(%Car{id: id} = car) do
    case get_current_state(car) do
      %State{start_date: date} = state ->
        query =
          from s in State,
            where: s.car_id == ^id and s.start_date > ^date,
            order_by: [asc: s.start_date],
            limit: 1

        end_date =
          case Repo.one(query) do
            %State{start_date: d} -> d
            nil -> DateTime.add(date, 1, :second)
          end

        with {:ok, _} <-
               state
               |> State.changeset(%{end_date: end_date})
               |> Repo.update() do
          :ok
        end

      nil ->
        :ok
    end
  end

  def get_earliest_state(%Car{id: id}) do
    State
    |> where(car_id: ^id)
    |> order_by(asc: :start_date)
    |> limit(1)
    |> Repo.one()
  end

  defp create_state(%Car{id: id}, attrs) do
    %State{car_id: id}
    |> State.changeset(attrs)
    |> Repo.insert()
  end

  ## Position

  def insert_position(%Drive{id: id, car_id: car_id}, attrs) do
    %Position{car_id: car_id, drive_id: id}
    |> Position.changeset(attrs)
    |> Repo.insert()
  end

  def insert_position(%Car{id: id}, attrs) do
    %Position{car_id: id}
    |> Position.changeset(attrs)
    |> Repo.insert()
  end

  def get_latest_position do
    Position
    |> order_by(desc: :date)
    |> limit(1)
    |> Repo.one()
  end

  def get_latest_position(%Car{id: id}) do
    Position
    |> where(car_id: ^id)
    |> order_by(desc: :date)
    |> limit(1)
    |> Repo.one()
  end

  def get_positions_without_elevation(min_id \\ 0, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    date_earliest =
      cond do
        min_id == 0 ->
          DateTime.add(DateTime.utc_now(), -10, :day)

        true ->
          {:ok, default_date_earliest, _} = DateTime.from_iso8601("2003-07-01T00:00:00Z")
          default_date_earliest
      end

    naive_date_earliest = DateTime.to_naive(date_earliest)

    non_streamed_drives =
      Repo.all(
        from(d in Drive,
          as: :d,
          where:
            d.start_date > ^naive_date_earliest and
              exists(
                from(p in Position,
                  where: p.drive_id == parent_as(:d).id and p.id > ^min_id
                )
              ) and
              not exists(
                from(p in Position,
                  where:
                    p.drive_id == parent_as(:d).id and p.id > ^min_id and
                      not is_nil(p.odometer) and is_nil(p.ideal_battery_range_km)
                )
              ),
          select: d.id
        )
      )

    Position
    |> where(
      [p],
      p.id > ^min_id and is_nil(p.elevation) and p.drive_id in ^non_streamed_drives and
        p.date > ^naive_date_earliest
    )
    |> order_by(asc: :id)
    |> limit(^limit)
    |> Repo.all()
    |> Enum.reverse()
    |> case do
      [%Position{id: next} | _] = positions ->
        {Enum.reverse(positions), next}

      [] ->
        {[], nil}
    end
  end

  def update_position(%Position{} = position, attrs) do
    position
    |> Position.changeset(attrs)
    |> Repo.update()
  end

  ## Drive

  def start_drive(%Car{id: id}) do
    %Drive{car_id: id}
    |> Drive.changeset(%{start_date: DateTime.utc_now()})
    |> Repo.insert()
  end

  def close_drive(%Drive{id: id} = drive, opts \\ []) do
    drive = Repo.preload(drive, [:car])

    drive_data =
      from p in Position,
        select: %{
          count: count() |> over(:w),
          start_position_id: first_value(p.id) |> over(:w),
          end_position_id: last_value(p.id) |> over(:w),
          outside_temp_avg: avg(p.outside_temp) |> over(:w),
          inside_temp_avg: avg(p.inside_temp) |> over(:w),
          speed_max: max(p.speed) |> over(:w),
          power_max: max(p.power) |> over(:w),
          power_min: min(p.power) |> over(:w),
          start_date: first_value(p.date) |> over(:w),
          end_date: last_value(p.date) |> over(:w),
          start_km: first_value(p.odometer) |> over(:w),
          end_km: last_value(p.odometer) |> over(:w),
          distance: (last_value(p.odometer) |> over(:w)) - (first_value(p.odometer) |> over(:w)),
          duration_min:
            fragment(
              "round(extract(epoch from (? - ?)) / 60)::integer",
              last_value(p.date) |> over(:w),
              first_value(p.date) |> over(:w)
            ),
          start_ideal_range_km: -1,
          end_ideal_range_km: -1,
          start_rated_range_km: -1,
          end_rated_range_km: -1,
          ascent: 0,
          descent: 0
        },
        windows: [
          w: [
            order_by:
              fragment("? RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING", p.date)
          ]
        ],
        where: p.drive_id == ^id,
        limit: 1

    non_streamed_drive_data =
      from p in Position,
        select: %{
          start_ideal_range_km: first_value(p.ideal_battery_range_km) |> over(:w),
          end_ideal_range_km: last_value(p.ideal_battery_range_km) |> over(:w),
          start_rated_range_km: first_value(p.rated_battery_range_km) |> over(:w),
          end_rated_range_km: last_value(p.rated_battery_range_km) |> over(:w)
        },
        windows: [
          w: [
            order_by:
              fragment("? RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING", p.date)
          ]
        ],
        where:
          p.drive_id == ^id and
            not is_nil(p.ideal_battery_range_km) and
            not is_nil(p.odometer),
        limit: 1

    # If the sum of elevation gains exceeds the max value of a smallint (32767), set it to 0.
    # If the sum of elevation losses exceeds the max value of a smallint (32767), set it to 0.
    elevation_data =
      from p1 in subquery(
             from p in Position,
               where: p.drive_id == ^id and not is_nil(p.elevation),
               select: %{
                 elevation_diff: p.elevation - (lag(p.elevation) |> over(order_by: [asc: p.date]))
               }
           ),
           select: %{
             elevation_gains:
               fragment(
                 "COALESCE(NULLIF(LEAST(SUM(CASE WHEN ? > 0 THEN ? ELSE 0 END), 32768), 32768), 0)",
                 p1.elevation_diff,
                 p1.elevation_diff
               ),
             elevation_losses:
               fragment(
                 "COALESCE(NULLIF(LEAST(SUM(CASE WHEN ? < 0 THEN ABS(?) ELSE 0 END), 32768), 32768), 0)",
                 p1.elevation_diff,
                 p1.elevation_diff
               )
           }

    query =
      from d0 in subquery(drive_data),
        join: d1 in subquery(non_streamed_drive_data),
        on: true,
        join: e in subquery(elevation_data),
        on: true,
        select: %{
          d0
          | start_ideal_range_km: d1.start_ideal_range_km,
            end_ideal_range_km: d1.end_ideal_range_km,
            start_rated_range_km: d1.start_rated_range_km,
            end_rated_range_km: d1.end_rated_range_km,
            ascent: e.elevation_gains,
            descent: e.elevation_losses
        }

    case Repo.one(query) do
      %{count: count, distance: distance} = attrs when count >= 2 and distance >= 0.01 ->
        lookup_address = Keyword.get(opts, :lookup_address, true)

        start_pos = Repo.get!(Position, attrs.start_position_id)
        end_pos = Repo.get!(Position, attrs.end_position_id)

        attrs =
          if lookup_address do
            attrs
            |> put_address(:start_address_id, start_pos)
            |> put_address(:end_address_id, end_pos)
          else
            attrs
          end

        attrs =
          attrs
          |> put_geofence(:start_geofence_id, start_pos)
          |> put_geofence(:end_geofence_id, end_pos)

        drive
        |> Drive.changeset(attrs)
        |> Repo.update()

      _ ->
        drive
        |> Drive.changeset(%{distance: 0, duration_min: 0})
        |> Repo.delete()
    end
  end

  defp put_address(attrs, key, position) do
    case Locations.find_address(position) do
      {:ok, %Locations.Address{id: id}} ->
        Map.put(attrs, key, id)

      {:error, reason} ->
        Logger.warning("Address not found: #{inspect(reason)}")
        attrs
    end
  end

  defp put_geofence(attrs, key, position) do
    case Locations.find_geofence(position) do
      %GeoFence{id: id} -> Map.put(attrs, key, id)
      nil -> attrs
    end
  end

  ## ChargingProcess

  def get_charging_process!(id) do
    ChargingProcess
    |> where(id: ^id)
    |> preload([:address, :geofence, :car, :position])
    |> Repo.one!()
  end

  def update_charging_process(%ChargingProcess{} = charge, attrs) do
    charge
    |> ChargingProcess.changeset(attrs)
    |> Repo.update()
  end

  def start_charging_process(%Car{id: id}, %{latitude: _, longitude: _} = attrs, opts \\ []) do
    lookup_address = Keyword.get(opts, :lookup_address, true)
    position = Map.put(attrs, :car_id, id)

    address_id =
      if lookup_address do
        case Locations.find_address(position) do
          {:ok, %Locations.Address{id: id}} ->
            id

          {:error, reason} ->
            Logger.warning("Address not found: #{inspect(reason)}")
            nil
        end
      end

    geofence_id =
      with %GeoFence{id: id} <- Locations.find_geofence(position) do
        id
      end

    with {:ok, cproc} <-
           %ChargingProcess{car_id: id, address_id: address_id, geofence_id: geofence_id}
           |> ChargingProcess.changeset(%{start_date: DateTime.utc_now(), position: position})
           |> Repo.insert() do
      {:ok, Repo.preload(cproc, [:address, :geofence])}
    end
  end

  def insert_charge(%ChargingProcess{id: id}, attrs) do
    %Charge{charging_process_id: id}
    |> Charge.changeset(attrs)
    |> Repo.insert()
  end

  def complete_charging_process(%ChargingProcess{} = charging_process) do
    charging_process = Repo.preload(charging_process, [{:car, :settings}, :geofence])
    settings = Settings.get_global_settings!()

    type =
      from(c in Charge,
        select: %{
          fast_charger_type: fragment("mode() WITHIN GROUP (ORDER BY ?)", c.fast_charger_type)
        },
        where: c.charging_process_id == ^charging_process.id and c.charger_power > 0
      )

    stats =
      from(c in Charge,
        join: t in subquery(type),
        on: true,
        select: %{
          start_date: first_value(c.date) |> over(:w),
          end_date: last_value(c.date) |> over(:w),
          start_ideal_range_km: first_value(c.ideal_battery_range_km) |> over(:w),
          end_ideal_range_km: last_value(c.ideal_battery_range_km) |> over(:w),
          start_rated_range_km: first_value(c.rated_battery_range_km) |> over(:w),
          end_rated_range_km: last_value(c.rated_battery_range_km) |> over(:w),
          start_battery_level: first_value(c.battery_level) |> over(:w),
          end_battery_level: last_value(c.battery_level) |> over(:w),
          outside_temp_avg: avg(c.outside_temp) |> over(:w),
          charge_energy_added:
            coalesce(
              nullif(last_value(c.charge_energy_added) |> over(:w), 0),
              max(c.charge_energy_added) |> over(:w)
            ) -
              (first_value(c.charge_energy_added) |> over(:w)),
          duration_min:
            duration_min(last_value(c.date) |> over(:w), first_value(c.date) |> over(:w)),
          fast_charger_type: t.fast_charger_type
        },
        windows: [
          w: [
            order_by:
              fragment("? RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING", c.date)
          ]
        ],
        where: [charging_process_id: ^charging_process.id],
        limit: 1
      )
      |> Repo.one() || %{end_date: DateTime.utc_now(), charge_energy_added: nil}

    charge_energy_used = calculate_energy_used(charging_process)

    attrs =
      stats
      |> Map.put(:charge_energy_used, charge_energy_used)
      |> Map.update(:charge_energy_added, nil, fn kwh ->
        cond do
          kwh == nil or Decimal.negative?(kwh) -> nil
          true -> kwh
        end
      end)
      |> put_cost(charging_process)

    with {:ok, cproc} <- charging_process |> ChargingProcess.changeset(attrs) |> Repo.update(),
         {:ok, _car} <- recalculate_efficiency(charging_process.car, settings) do
      {:ok, cproc}
    end
  end

  def update_energy_used(%ChargingProcess{} = charging_process) do
    charging_process
    |> ChargingProcess.changeset(%{charge_energy_used: calculate_energy_used(charging_process)})
    |> Repo.update()
  end

  defp calculate_energy_used(%ChargingProcess{id: id} = charging_process) do
    phases = determine_phases(charging_process)

    query =
      from c in Charge,
        select: %{
          energy_used:
            c_if is_nil(c.charger_phases) do
              c.charger_power
            else
              c.charger_actual_current * c.charger_voltage * type(^phases, :float) / 1000.0
            end *
              fragment(
                "EXTRACT(epoch FROM (?))",
                c.date - (lag(c.date) |> over(order_by: c.date))
              ) / 3600
        },
        where: c.charging_process_id == ^id

    Repo.one(
      from e in subquery(query),
        select: sum(e.energy_used) |> type(:decimal),
        where: e.energy_used >= 0
    )
  end

  defp determine_phases(%ChargingProcess{id: id, car_id: car_id}) do
    from(c in Charge,
      select: {
        avg(c.charger_power * 1000.0 / nullif(c.charger_actual_current * c.charger_voltage, 0))
        |> type(:float),
        avg(c.charger_phases) |> type(:integer),
        avg(c.charger_voltage) |> type(:float),
        count()
      },
      group_by: c.charging_process_id,
      where: c.charging_process_id == ^id
    )
    |> Repo.one()
    |> case do
      {p, r, v, n} when not is_nil(p) and p > 0 and n > 15 ->
        cond do
          r == round(p) ->
            r

          r == 3 and abs(p / :math.sqrt(r) - 1) <= 0.1 ->
            Logger.info("Voltage correction: #{round(v)}V -> #{round(v / :math.sqrt(r))}V",
              car_id: car_id
            )

            :math.sqrt(r)

          abs(round(p) - p) <= 0.3 ->
            Logger.info("Phase correction: #{r} -> #{round(p)}", car_id: car_id)
            round(p)

          true ->
            nil
        end

      _ ->
        nil
    end
  end

  defp put_cost(stats, %ChargingProcess{} = charging_process) do
    alias ChargingProcess, as: CP

    cost =
      case {stats, charging_process} do
        {%{fast_charger_type: "Tesla" <> _},
         %CP{car: %Car{settings: %CarSettings{free_supercharging: true}}}} ->
          0.0

        {%{charge_energy_used: kwh_used, charge_energy_added: kwh_added},
         %CP{
           geofence: %GeoFence{
             billing_type: :per_kwh,
             cost_per_unit: cost_per_kwh,
             session_fee: session_fee
           }
         }} ->
          if match?(%Decimal{}, kwh_used) or match?(%Decimal{}, kwh_added) do
            cost =
              with %Decimal{} <- cost_per_kwh do
                [kwh_added, kwh_used]
                |> Enum.reject(&is_nil/1)
                |> Enum.max(Decimal)
                |> Decimal.mult(cost_per_kwh)
              end

            if match?(%Decimal{}, cost) or match?(%Decimal{}, session_fee) do
              Decimal.add(session_fee || 0, cost || 0)
            end
          end

        {%{duration_min: minutes},
         %CP{
           geofence: %GeoFence{
             billing_type: :per_minute,
             cost_per_unit: cost_per_minute,
             session_fee: session_fee
           }
         }}
        when is_number(minutes) ->
          cost = Decimal.mult(minutes, cost_per_minute)
          Decimal.add(session_fee || 0, cost)

        {_, _} ->
          nil
      end

    Map.put(stats, :cost, cost)
  end

  defp recalculate_efficiency(car, settings, opts \\ [{5, 8}, {4, 5}, {3, 3}, {2, 2}])
  defp recalculate_efficiency(car, _settings, []), do: {:ok, car}

  defp recalculate_efficiency(%Car{id: id} = car, settings, [{precision, threshold} | opts]) do
    {start_range, end_range} =
      case settings do
        %GlobalSettings{preferred_range: :ideal} ->
          {:start_ideal_range_km, :end_ideal_range_km}

        %GlobalSettings{preferred_range: :rated} ->
          {:start_rated_range_km, :end_rated_range_km}
      end

    query =
      from c in ChargingProcess,
        select: {
          round(
            c.charge_energy_added / nullif(field(c, ^end_range) - field(c, ^start_range), 0),
            ^precision
          ),
          count()
        },
        where:
          c.car_id == ^id and c.duration_min > 10 and c.end_battery_level <= 95 and
            not is_nil(field(c, ^end_range)) and not is_nil(field(c, ^start_range)) and
            c.charge_energy_added > 0.0,
        group_by: 1,
        order_by: [desc: 2],
        limit: 1

    case Repo.one(query) do
      {factor, n} when n >= threshold and not is_nil(factor) and factor > 0 ->
        Logger.info("Derived efficiency factor: #{factor * 1000} Wh/km (#{n}x confirmed)",
          car_id: id
        )

        car
        |> Car.changeset(%{efficiency: factor})
        |> Repo.update()

      _ ->
        recalculate_efficiency(car, settings, opts)
    end
  end

  ## Update

  def start_update(%Car{id: id}, opts \\ []) do
    start_date = Keyword.get(opts, :date) || DateTime.utc_now()

    %Update{car_id: id}
    |> Update.changeset(%{start_date: start_date})
    |> Repo.insert()
  end

  def cancel_update(%Update{} = update) do
    Repo.delete(update)
  end

  def finish_update(%Update{} = update, version, opts \\ []) do
    end_date = Keyword.get(opts, :date) || DateTime.utc_now()

    update
    |> Update.changeset(%{end_date: end_date, version: version})
    |> Repo.update()
  end

  def get_latest_update(%Car{id: id}) do
    from(u in Update, where: [car_id: ^id], order_by: [desc: :start_date], limit: 1)
    |> Repo.one()
  end

  def insert_missed_update(%Car{id: id}, version, opts \\ []) do
    date = Keyword.get(opts, :date) || DateTime.utc_now()

    %Update{car_id: id}
    |> Update.changeset(%{start_date: date, end_date: date, version: version})
    |> Repo.insert()
  end

  ## Stats Queries

  defp stats_date_filter(query, field, opts) do
    from_dt = Keyword.get(opts, :from)
    to_dt = Keyword.get(opts, :to)

    query
    |> maybe_filter_from(field, from_dt)
    |> maybe_filter_to(field, to_dt)
  end

  defp maybe_filter_from(query, _field, nil), do: query
  defp maybe_filter_from(query, :start_date, from), do: from(q in query, where: q.start_date >= ^from)
  defp maybe_filter_from(query, :date, from), do: from(q in query, where: q.date >= ^from)

  defp maybe_filter_to(query, _field, nil), do: query
  defp maybe_filter_to(query, :start_date, to), do: from(q in query, where: q.start_date <= ^to)
  defp maybe_filter_to(query, :date, to), do: from(q in query, where: q.date <= ^to)

  def stats_battery_health(car_id, opts \\ []) do
    query =
      from c in Charge,
        join: cp in ChargingProcess, on: c.charging_process_id == cp.id,
        where: cp.car_id == ^car_id and c.battery_level == 100 and not is_nil(c.rated_battery_range_km),
        select: %{
          date: c.date,
          rated_range_km: c.rated_battery_range_km,
          battery_level: c.battery_level,
          soh_estimate: c.rated_battery_range_km
        },
        order_by: [asc: c.date]

    query = stats_date_filter(query, :date, opts)
    points = Repo.all(query)

    current_soh =
      case List.last(points) do
        nil -> nil
        p -> p.soh_estimate
      end

    # Summary stats from charging processes
    summary_query =
      from cp in ChargingProcess,
        where: cp.car_id == ^car_id and not is_nil(cp.charge_energy_added),
        select: %{
          total_charges: count(cp.id),
          total_energy_added: sum(cp.charge_energy_added),
          ac_energy_kwh: fragment("SUM(?.charge_energy_added) FILTER (WHERE NOT EXISTS (SELECT 1 FROM charges c WHERE c.charging_process_id = ?.id AND c.fast_charger_present = true))", cp, cp),
          dc_energy_kwh: fragment("SUM(?.charge_energy_added) FILTER (WHERE EXISTS (SELECT 1 FROM charges c WHERE c.charging_process_id = ?.id AND c.fast_charger_present = true))", cp, cp)
        }

    summary_query = stats_date_filter(summary_query, :start_date, opts)
    summary = Repo.one(summary_query) || %{total_charges: 0, total_energy_added: nil, ac_energy_kwh: nil, dc_energy_kwh: nil}

    # Usable capacity: avg rated range from last 10 charges to 100%
    capacity_query =
      from c in Charge,
        join: cp in ChargingProcess, on: c.charging_process_id == cp.id,
        where: cp.car_id == ^car_id and c.battery_level == 100 and not is_nil(c.rated_battery_range_km),
        select: c.rated_battery_range_km,
        order_by: [desc: c.date],
        limit: 10

    recent_ranges = Repo.all(capacity_query)
    usable_capacity_kwh =
      case recent_ranges do
        [] -> nil
        ranges ->
          avg_range = Enum.reduce(ranges, Decimal.new(0), &Decimal.add/2) |> Decimal.div(length(ranges))
          avg_range
      end

    %{
      current_soh: current_soh,
      points: points,
      total_charges: summary.total_charges,
      total_energy_added: summary.total_energy_added,
      ac_energy_kwh: summary.ac_energy_kwh,
      dc_energy_kwh: summary.dc_energy_kwh,
      usable_capacity_km: usable_capacity_kwh
    }
  end

  def stats_projected_range(car_id, opts \\ []) do
    query =
      from c in Charge,
        join: cp in ChargingProcess, on: c.charging_process_id == cp.id,
        left_join: p in Position, on: p.id == cp.position_id,
        where: cp.car_id == ^car_id and c.battery_level == 100 and
               not is_nil(c.rated_battery_range_km) and not is_nil(c.ideal_battery_range_km),
        select: %{
          date: c.date,
          rated_range_km: c.rated_battery_range_km,
          ideal_range_km: c.ideal_battery_range_km,
          battery_level: c.battery_level,
          odometer_km: p.odometer,
          outside_temp: c.outside_temp
        },
        order_by: [asc: c.date]

    query = stats_date_filter(query, :date, opts)
    %{points: Repo.all(query)}
  end

  def stats_charge_level(car_id, opts \\ []) do
    query =
      from p in Position,
        where: p.car_id == ^car_id and not is_nil(p.battery_level),
        select: %{
          date: p.date,
          battery_level: p.battery_level,
          usable_battery_level: p.usable_battery_level
        },
        order_by: [desc: p.date],
        limit: 1000

    query = stats_date_filter(query, :date, opts)
    points = Repo.all(query) |> Enum.reverse()

    current =
      case List.last(points) do
        nil -> nil
        p -> p.battery_level
      end

    %{current: current, points: points}
  end

  def stats_vampire_drain(car_id, opts \\ []) do
    min_idle_hours = Keyword.get(opts, :min_idle_hours, 1)

    # Find idle periods (state = asleep or online without driving/charging)
    query =
      from s in State,
        where: s.car_id == ^car_id and s.state in [:asleep, :online] and
               not is_nil(s.end_date) and
               fragment("EXTRACT(epoch FROM (? - ?)) / 3600", s.end_date, s.start_date) > ^min_idle_hours,
        select: %{
          date: s.start_date,
          start_date: s.start_date,
          end_date: s.end_date,
          duration_hours: fragment("EXTRACT(epoch FROM (? - ?)) / 3600", s.end_date, s.start_date)
        },
        order_by: [desc: s.start_date],
        limit: 200

    query = stats_date_filter(query, :start_date, opts)
    idle_periods = Repo.all(query)

    points =
      Enum.map(idle_periods, fn period ->
        start_pos =
          from(p in Position,
            where: p.car_id == ^car_id and p.date >= ^period.start_date and not is_nil(p.battery_level),
            order_by: [asc: p.date],
            limit: 1
          )
          |> Repo.one()

        end_pos =
          from(p in Position,
            where: p.car_id == ^car_id and p.date <= ^period.end_date and not is_nil(p.battery_level),
            order_by: [desc: p.date],
            limit: 1
          )
          |> Repo.one()

        case {start_pos, end_pos} do
          {%{battery_level: sl} = sp, %{battery_level: el} = ep} when not is_nil(sl) and not is_nil(el) and sl > el ->
            loss = sl - el
            hours = period.duration_hours
            # Compute range values if available
            start_range = sp |> Map.get(:rated_battery_range_km)
            end_range = ep |> Map.get(:rated_battery_range_km)
            range_diff = if start_range && end_range, do: start_range - end_range, else: nil
            outside_temp = sp |> Map.get(:outside_temp)
            # Standby percentage: time in this state vs total period
            total_seconds = hours * 3600
            avg_power = if hours > 0 && range_diff, do: range_diff * 1000 / hours, else: nil

            %{
              date: period.start_date,
              start_date: period.start_date,
              end_date: period.end_date,
              start_level: sl,
              end_level: el,
              duration_hours: hours,
              loss_per_hour: if(hours > 0, do: loss / hours, else: 0),
              start_range_km: start_range,
              end_range_km: end_range,
              range_diff_km: range_diff,
              avg_power_watts: avg_power,
              standby_percentage: if(sl > 0, do: loss / sl * 100, else: 0),
              outside_temp: outside_temp
            }

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    avg =
      case points do
        [] -> nil
        pts -> Enum.sum(Enum.map(pts, & &1.loss_per_hour)) / length(pts)
      end

    %{avg_loss_per_hour: avg, points: points}
  end

  def stats_drives(car_id, opts \\ []) do
    bucket = Keyword.get(opts, :bucket, "month")

    base_query =
      from d in Drive,
        where: d.car_id == ^car_id and not is_nil(d.end_date)

    base_query = stats_date_filter(base_query, :start_date, opts)

    totals_query =
      from d in base_query,
        select: %{
          total_drives: count(d.id),
          total_distance_km: sum(d.distance),
          total_duration_min: sum(d.duration_min),
          total_energy_kwh: fragment("SUM(? - ?)", d.start_rated_range_km, d.end_rated_range_km),
          avg_speed: fragment("CASE WHEN SUM(?) > 0 THEN SUM(?) / (SUM(?) / 60.0) END", d.duration_min, d.distance, d.duration_min)
        }

    totals = Repo.one(totals_query) || %{total_drives: 0, total_distance_km: nil, total_duration_min: 0, total_energy_kwh: nil, avg_speed: nil}

    buckets_query =
      from d in base_query,
        select: %{
          period: fragment("date_trunc(?, ?)", ^bucket, d.start_date),
          count: count(d.id),
          distance_km: sum(d.distance),
          duration_min: sum(d.duration_min),
          energy_kwh: fragment("SUM(? - ?)", d.start_rated_range_km, d.end_rated_range_km)
        },
        group_by: fragment("date_trunc(?, ?)", ^bucket, d.start_date),
        order_by: fragment("date_trunc(?, ?)", ^bucket, d.start_date)

    buckets = Repo.all(buckets_query)

    %{totals: totals, buckets: buckets}
  end

  def stats_efficiency(car_id, opts \\ []) do
    query =
      from d in Drive,
        where: d.car_id == ^car_id and not is_nil(d.end_date) and d.distance > 0 and
               not is_nil(d.start_rated_range_km) and not is_nil(d.end_rated_range_km),
        select: %{
          date: d.start_date,
          distance_km: d.distance,
          energy_kwh: fragment("? - ?", d.start_rated_range_km, d.end_rated_range_km),
          efficiency_wh_km: fragment("CASE WHEN ? > 0 THEN (? - ?) * 1000.0 / ? END",
            d.distance, d.start_rated_range_km, d.end_rated_range_km, d.distance),
          outside_temp_avg: d.outside_temp_avg,
          speed_avg: fragment("CASE WHEN ? > 0 THEN ? / (? / 60.0) END",
            d.duration_min, d.distance, d.duration_min)
        },
        order_by: [asc: d.start_date]

    query = stats_date_filter(query, :start_date, opts)
    points = Repo.all(query)

    avg =
      case points do
        [] -> nil
        pts ->
          total_energy = Enum.sum(Enum.map(pts, fn p -> (p.energy_kwh || 0) end))
          total_dist = Enum.sum(Enum.map(pts, fn p -> (p.distance_km || 0) end))
          if total_dist > 0, do: total_energy * 1000 / total_dist, else: nil
      end

    # Rated efficiency from car settings
    rated_efficiency =
      case Repo.one(from c in Car, where: c.id == ^car_id, select: c.efficiency) do
        nil -> nil
        eff -> eff * 1000  # Convert kWh/km to Wh/km
      end

    # Net consumption (actual energy used from wall to wheel)
    net_consumption =
      case points do
        [] -> nil
        pts ->
          total_dist = Enum.sum(Enum.map(pts, fn p -> (p.distance_km || 0) end))
          total_energy_kwh = Enum.sum(Enum.map(pts, fn p -> (p.energy_kwh || 0) end))
          if total_dist > 0, do: total_energy_kwh * 1000 / total_dist, else: nil
      end

    # Temperature buckets: group drives by 5°C bins
    temp_buckets =
      points
      |> Enum.filter(fn p -> p.outside_temp_avg != nil end)
      |> Enum.group_by(fn p ->
        temp = if is_struct(p.outside_temp_avg, Decimal), do: Decimal.to_float(p.outside_temp_avg), else: p.outside_temp_avg
        Float.floor(temp / 5) * 5
      end)
      |> Enum.map(fn {bucket_temp, drives} ->
        count = length(drives)
        avg_eff = Enum.sum(Enum.map(drives, fn d -> (d.efficiency_wh_km || 0) end)) / count
        avg_speed = Enum.sum(Enum.map(drives, fn d -> (d.speed_avg || 0) end)) / count
        total_dist = Enum.sum(Enum.map(drives, fn d -> (d.distance_km || 0) end))
        %{
          temp_bucket: bucket_temp,
          count: count,
          avg_efficiency: avg_eff,
          avg_speed: avg_speed,
          total_distance_km: total_dist
        }
      end)
      |> Enum.sort_by(& &1.temp_bucket)

    %{
      avg_efficiency: avg,
      rated_efficiency: rated_efficiency,
      net_consumption_wh_km: net_consumption,
      temperature_buckets: temp_buckets,
      points: points
    }
  end

  def stats_mileage(car_id, opts \\ []) do
    bucket = Keyword.get(opts, :bucket, "month")

    base_query =
      from d in Drive,
        where: d.car_id == ^car_id and not is_nil(d.end_date)

    base_query = stats_date_filter(base_query, :start_date, opts)

    buckets_query =
      from d in base_query,
        select: %{
          period: fragment("date_trunc(?, ?)", ^bucket, d.start_date),
          distance_km: sum(d.distance)
        },
        group_by: fragment("date_trunc(?, ?)", ^bucket, d.start_date),
        order_by: fragment("date_trunc(?, ?)", ^bucket, d.start_date)

    buckets = Repo.all(buckets_query)

    # Calculate cumulative totals
    {buckets_with_cumulative, _} =
      Enum.map_reduce(buckets, 0, fn b, acc ->
        cumulative = acc + (b.distance_km || 0)
        {Map.put(b, :cumulative_km, cumulative), cumulative}
      end)

    odometer =
      from(p in Position,
        where: p.car_id == ^car_id and not is_nil(p.odometer),
        order_by: [desc: p.date],
        limit: 1,
        select: p.odometer
      )
      |> Repo.one()

    %{current_odometer: odometer, buckets: buckets_with_cumulative}
  end

  def stats_visited_heatmap(car_id, opts \\ []) do
    cell = 0.01

    query =
      from p in Position,
        where: p.car_id == ^car_id and not is_nil(p.latitude) and not is_nil(p.longitude),
        select: %{
          latitude: fragment("round(?::numeric / ? , 0) * ?", p.latitude, ^cell, ^cell),
          longitude: fragment("round(?::numeric / ? , 0) * ?", p.longitude, ^cell, ^cell),
          count: count(p.id)
        },
        group_by: [
          fragment("round(?::numeric / ? , 0) * ?", p.latitude, ^cell, ^cell),
          fragment("round(?::numeric / ? , 0) * ?", p.longitude, ^cell, ^cell)
        ],
        having: count(p.id) > 1

    query = stats_date_filter(query, :date, opts)
    Repo.all(query)
  end

  def stats_visited_routes(car_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    query =
      from d in Drive,
        where: d.car_id == ^car_id and not is_nil(d.end_date) and
               not is_nil(d.start_address_id) and not is_nil(d.end_address_id),
        preload: [:start_address, :end_address],
        select: %{
          drive_id: d.id,
          start_address_id: d.start_address_id,
          end_address_id: d.end_address_id
        },
        order_by: [desc: d.start_date],
        limit: ^limit

    query = stats_date_filter(query, :start_date, opts)
    drives = Repo.all(query) |> Repo.preload([:start_address, :end_address])

    # Group by route (start→end address pair)
    drives
    |> Enum.group_by(fn d -> {d.start_address_id, d.end_address_id} end)
    |> Enum.map(fn {{_sa, _ea}, drives_group} ->
      first = List.first(drives_group)
      %{
        drive_id: first.id,
        start_address: first.start_address,
        end_address: first.end_address,
        count: length(drives_group),
        total_distance_km: Enum.sum(Enum.map(drives_group, fn d -> d.distance || 0 end))
      }
    end)
    |> Enum.sort_by(& &1.count, :desc)
    |> Enum.take(limit)
  end

  def stats_visited_places(car_id, opts \\ []) do
    # Places visited: addresses from drives and charges
    drive_addresses =
      from d in Drive,
        where: d.car_id == ^car_id and not is_nil(d.end_date) and not is_nil(d.end_address_id),
        select: %{address_id: d.end_address_id, geofence_id: d.end_geofence_id}

    drive_addresses = stats_date_filter(drive_addresses, :start_date, opts)

    charge_addresses =
      from cp in ChargingProcess,
        where: cp.car_id == ^car_id and not is_nil(cp.end_date) and not is_nil(cp.address_id),
        select: %{address_id: cp.address_id, geofence_id: cp.geofence_id}

    charge_addresses = stats_date_filter(charge_addresses, :start_date, opts)

    drive_counts =
      from(d in subquery(drive_addresses),
        group_by: [d.address_id, d.geofence_id],
        select: %{address_id: d.address_id, geofence_id: d.geofence_id, count: count()}
      )
      |> Repo.all()

    charge_counts =
      from(c in subquery(charge_addresses),
        group_by: [c.address_id, c.geofence_id],
        select: %{address_id: c.address_id, geofence_id: c.geofence_id, count: count()}
      )
      |> Repo.all()

    # Merge drive and charge counts
    all_places =
      (drive_counts ++ charge_counts)
      |> Enum.group_by(& &1.address_id)
      |> Enum.map(fn {address_id, entries} ->
        visit_count = Enum.sum(for e <- entries, do: e.count)
        charge_count = Enum.sum(for e <- charge_counts, e.address_id == address_id, do: e.count)
        geofence_id = Enum.find_value(entries, & &1.geofence_id)

        address = Repo.get(TeslaMate.Locations.Address, address_id)
        geofence = if geofence_id, do: Repo.get(TeslaMate.Locations.GeoFence, geofence_id)

        %{
          address: address,
          geofence: geofence,
          visit_count: visit_count,
          charge_count: charge_count,
          latitude: if(address, do: address.latitude),
          longitude: if(address, do: address.longitude)
        }
      end)
      |> Enum.sort_by(& &1.visit_count, :desc)
      |> Enum.take(100)

    all_places
  end

  def stats_charging(car_id, opts \\ []) do
    bucket = Keyword.get(opts, :bucket, "month")

    base_query =
      from cp in ChargingProcess,
        where: cp.car_id == ^car_id and not is_nil(cp.end_date)

    base_query = stats_date_filter(base_query, :start_date, opts)

    totals_query =
      from cp in base_query,
        select: %{
          total_energy_kwh: sum(cp.charge_energy_added),
          total_cost: sum(cp.cost),
          total_sessions: count(cp.id),
          avg_energy_kwh: avg(cp.charge_energy_added),
          ac_sessions: fragment("COUNT(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM charges c WHERE c.charging_process_id = ? AND c.fast_charger_present = true))", cp.id),
          dc_sessions: fragment("COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM charges c WHERE c.charging_process_id = ? AND c.fast_charger_present = true))", cp.id),
          ac_energy_kwh: fragment("SUM(?.charge_energy_added) FILTER (WHERE NOT EXISTS (SELECT 1 FROM charges c WHERE c.charging_process_id = ?.id AND c.fast_charger_present = true))", cp, cp),
          dc_energy_kwh: fragment("SUM(?.charge_energy_added) FILTER (WHERE EXISTS (SELECT 1 FROM charges c WHERE c.charging_process_id = ?.id AND c.fast_charger_present = true))", cp, cp),
          ac_duration_min: fragment("SUM(EXTRACT(epoch FROM (?.end_date - ?.start_date)) / 60) FILTER (WHERE NOT EXISTS (SELECT 1 FROM charges c WHERE c.charging_process_id = ?.id AND c.fast_charger_present = true))", cp, cp, cp),
          dc_duration_min: fragment("SUM(EXTRACT(epoch FROM (?.end_date - ?.start_date)) / 60) FILTER (WHERE EXISTS (SELECT 1 FROM charges c WHERE c.charging_process_id = ?.id AND c.fast_charger_present = true))", cp, cp, cp)
        }

    totals = Repo.one(totals_query) || %{total_energy_kwh: nil, total_cost: nil, total_sessions: 0, avg_energy_kwh: nil, ac_sessions: 0, dc_sessions: 0, ac_energy_kwh: nil, dc_energy_kwh: nil, ac_duration_min: nil, dc_duration_min: nil}

    buckets_query =
      from cp in base_query,
        select: %{
          period: fragment("date_trunc(?, ?)", ^bucket, cp.start_date),
          energy_kwh: sum(cp.charge_energy_added),
          cost: sum(cp.cost),
          sessions: count(cp.id),
          ac_energy_kwh: fragment("SUM(?.charge_energy_added) FILTER (WHERE NOT EXISTS (SELECT 1 FROM charges c WHERE c.charging_process_id = ?.id AND c.fast_charger_present = true))", cp, cp),
          dc_energy_kwh: fragment("SUM(?.charge_energy_added) FILTER (WHERE EXISTS (SELECT 1 FROM charges c WHERE c.charging_process_id = ?.id AND c.fast_charger_present = true))", cp, cp)
        },
        group_by: fragment("date_trunc(?, ?)", ^bucket, cp.start_date),
        order_by: fragment("date_trunc(?, ?)", ^bucket, cp.start_date)

    buckets = Repo.all(buckets_query)

    %{totals: totals, buckets: buckets}
  end

  def stats_top_charging_stations(car_id, opts \\ []) do
    query =
      from cp in ChargingProcess,
        join: a in Address, on: cp.address_id == a.id,
        where: cp.car_id == ^car_id and not is_nil(cp.end_date),
        group_by: [a.id, a.display_name, a.city, a.country, a.latitude, a.longitude],
        select: %{
          address_id: a.id,
          display_name: a.display_name,
          city: a.city,
          country: a.country,
          latitude: a.latitude,
          longitude: a.longitude,
          sessions: count(cp.id),
          total_energy_kwh: sum(cp.charge_energy_added),
          total_cost: sum(cp.cost)
        },
        order_by: [desc: count(cp.id)],
        limit: 20

    query = stats_date_filter(query, :start_date, opts)
    Repo.all(query)
  end

  def stats_dc_curve(car_id, opts \\ []) do
    query =
      from c in Charge,
        join: cp in ChargingProcess, on: c.charging_process_id == cp.id,
        where: cp.car_id == ^car_id and c.fast_charger_present == true and c.charger_power > 0,
        select: %{
          battery_level: c.battery_level,
          charger_power: c.charger_power,
          charge_energy_added: c.charge_energy_added,
          charger_voltage: c.charger_voltage,
          outside_temp: c.outside_temp
        },
        order_by: [asc: c.battery_level]

    query = stats_date_filter(query, :date, opts)
    Repo.all(query)
  end

  def stats_states(car_id, opts \\ []) do
    query =
      from s in State,
        where: s.car_id == ^car_id and not is_nil(s.end_date),
        select: %{
          state: s.state,
          start_date: s.start_date,
          end_date: s.end_date,
          duration_min: fragment("round(EXTRACT(epoch FROM (? - ?)) / 60)::integer", s.end_date, s.start_date)
        },
        order_by: [desc: s.start_date],
        limit: 500

    query = stats_date_filter(query, :start_date, opts)
    Repo.all(query)
  end

  def stats_timeline(car_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 50) |> min(100)
    offset = (page - 1) * per_page
    search = Keyword.get(opts, :search)

    # Drives
    drives_query =
      from d in Drive,
        where: d.car_id == ^car_id and not is_nil(d.end_date),
        preload: [:start_address, :end_address, :start_geofence, :end_geofence],
        select: %{type: "drive", id: d.id, start_date: d.start_date, end_date: d.end_date,
                  distance: d.distance, start_address_id: d.start_address_id, end_address_id: d.end_address_id}

    drives_query = stats_date_filter(drives_query, :start_date, opts)
    drives = Repo.all(drives_query) |> Repo.preload([:start_address, :end_address])

    drive_entries =
      Enum.map(drives, fn d ->
        start_name = if(d.start_address, do: d.start_address.display_name, else: "Unknown")
        end_name = if(d.end_address, do: d.end_address.display_name, else: "Unknown")
        %{
          type: "drive",
          id: d.id,
          start_date: d.start_date,
          end_date: d.end_date,
          title: "#{start_name} → #{end_name}",
          subtitle: if(d.distance, do: "#{Float.round(d.distance * 1.0, 1)} km", else: nil),
          distance_km: d.distance,
          energy_kwh: if(d.start_rated_range_km && d.end_rated_range_km, do: d.start_rated_range_km - d.end_rated_range_km, else: nil),
          start_soc: d.start_battery_level,
          end_soc: d.end_battery_level,
          outside_temp: d.outside_temp_avg
        }
      end)

    # Charges
    charges_query =
      from cp in ChargingProcess,
        where: cp.car_id == ^car_id and not is_nil(cp.end_date),
        preload: [:address, :geofence]

    charges_query = stats_date_filter(charges_query, :start_date, opts)
    charges = Repo.all(charges_query)

    charge_entries =
      Enum.map(charges, fn cp ->
        location = cond do
          cp.geofence -> cp.geofence.name
          cp.address -> cp.address.display_name
          true -> "Unknown"
        end
        %{
          type: "charge",
          id: cp.id,
          start_date: cp.start_date,
          end_date: cp.end_date,
          title: location,
          subtitle: if(cp.charge_energy_added, do: "#{Decimal.to_float(cp.charge_energy_added) |> Float.round(1)} kWh", else: nil),
          energy_added_kwh: cp.charge_energy_added,
          cost: cp.cost,
          address: location,
          start_soc: cp.start_battery_level,
          end_soc: cp.end_battery_level
        }
      end)

    # Updates
    updates_query =
      from u in Update,
        where: u.car_id == ^car_id and not is_nil(u.end_date)

    updates_query = stats_date_filter(updates_query, :start_date, opts)
    updates_list = Repo.all(updates_query)

    update_entries =
      Enum.map(updates_list, fn u ->
        %{
          type: "update",
          id: u.id,
          start_date: u.start_date,
          end_date: u.end_date,
          title: "Software Update",
          subtitle: u.version
        }
      end)

    # Combine and sort all events
    all_events =
      (drive_entries ++ charge_entries ++ update_entries)
      |> Enum.sort_by(& &1.start_date, {:desc, DateTime})

    # Generate parking events from gaps between consecutive events
    sorted_asc = Enum.reverse(all_events)
    parking_entries =
      sorted_asc
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.flat_map(fn [prev, next] ->
        if prev.end_date && next.start_date do
          gap_seconds = DateTime.diff(next.start_date, prev.end_date)
          if gap_seconds > 300 do
            [%{
              type: "parking",
              id: nil,
              start_date: prev.end_date,
              end_date: next.start_date,
              title: "Parked",
              subtitle: format_duration_seconds(gap_seconds)
            }]
          else
            []
          end
        else
          []
        end
      end)

    all_with_parking =
      (all_events ++ parking_entries)
      |> Enum.sort_by(& &1.start_date, {:desc, DateTime})

    # Apply search filter if provided
    filtered =
      case search do
        nil -> all_with_parking
        "" -> all_with_parking
        term ->
          search_lower = String.downcase(term)
          Enum.filter(all_with_parking, fn entry ->
            title = String.downcase(entry.title || "")
            subtitle = String.downcase(entry[:subtitle] || "")
            address = String.downcase(to_string(entry[:address] || ""))
            String.contains?(title, search_lower) ||
              String.contains?(subtitle, search_lower) ||
              String.contains?(address, search_lower)
          end)
      end

    total = length(filtered)
    paginated = filtered |> Enum.drop(offset) |> Enum.take(per_page)

    %{entries: paginated, page: page, per_page: per_page, total: total}
  end

  defp format_duration_seconds(seconds) when seconds >= 86400 do
    days = div(seconds, 86400)
    hours = div(rem(seconds, 86400), 3600)
    "#{days}d #{hours}h"
  end
  defp format_duration_seconds(seconds) when seconds >= 3600 do
    hours = div(seconds, 3600)
    mins = div(rem(seconds, 3600), 60)
    "#{hours}h #{mins}m"
  end
  defp format_duration_seconds(seconds) do
    "#{div(seconds, 60)}m"
  end

  def stats_updates(car_id, opts \\ []) do
    query =
      from u in Update,
        where: u.car_id == ^car_id and not is_nil(u.end_date),
        select: %{
          version: u.version,
          start_date: u.start_date,
          end_date: u.end_date
        },
        order_by: [desc: u.start_date]

    query = stats_date_filter(query, :start_date, opts)
    Repo.all(query)
  end

  def stats_statistics(car_id, opts \\ []) do
    bucket = Keyword.get(opts, :bucket, "month")

    base_drives =
      from d in Drive,
        where: d.car_id == ^car_id and not is_nil(d.end_date) and d.distance > 0

    base_drives = stats_date_filter(base_drives, :start_date, opts)

    base_charges =
      from cp in ChargingProcess,
        where: cp.car_id == ^car_id and not is_nil(cp.end_date)

    base_charges = stats_date_filter(base_charges, :start_date, opts)

    # Bucketed drive stats
    drive_buckets =
      from d in base_drives,
        select: %{
          period: fragment("date_trunc(?, ?)", ^bucket, d.start_date),
          time_driven_min: sum(d.duration_min),
          distance_km: sum(d.distance),
          avg_temp: avg(d.outside_temp_avg),
          avg_speed: fragment("CASE WHEN SUM(?) > 0 THEN SUM(?) / (SUM(?) / 60.0) END",
            d.duration_min, d.distance, d.duration_min),
          energy_kwh: fragment("SUM(? - ?)", d.start_rated_range_km, d.end_rated_range_km),
          drives: count(d.id),
          gross_consumption_wh_km: fragment("CASE WHEN SUM(?) > 0 THEN SUM(? - ?) * 1000.0 / SUM(?) END",
            d.distance, d.start_rated_range_km, d.end_rated_range_km, d.distance)
        },
        group_by: fragment("date_trunc(?, ?)", ^bucket, d.start_date),
        order_by: fragment("date_trunc(?, ?)", ^bucket, d.start_date)

    drive_data = Repo.all(drive_buckets)

    # Bucketed charge stats
    charge_buckets =
      from cp in base_charges,
        select: %{
          period: fragment("date_trunc(?, ?)", ^bucket, cp.start_date),
          charges: count(cp.id),
          energy_added_kwh: sum(cp.charge_energy_added),
          total_cost: sum(cp.cost)
        },
        group_by: fragment("date_trunc(?, ?)", ^bucket, cp.start_date),
        order_by: fragment("date_trunc(?, ?)", ^bucket, cp.start_date)

    charge_data = Repo.all(charge_buckets)

    # Merge drive and charge buckets by period
    charge_map = Map.new(charge_data, fn c -> {c.period, c} end)

    buckets =
      Enum.map(drive_data, fn d ->
        c = Map.get(charge_map, d.period, %{charges: 0, energy_added_kwh: nil, total_cost: nil})
        total_cost = c[:total_cost]
        energy_added = c[:energy_added_kwh]
        distance = d.distance_km

        cost_per_kwh = if total_cost && energy_added && energy_added > 0, do: total_cost / energy_added, else: nil
        cost_per_100km = if total_cost && distance && distance > 0, do: total_cost / distance * 100, else: nil

        %{
          period: d.period,
          time_driven_min: d.time_driven_min,
          distance_km: d.distance_km,
          avg_temp: d.avg_temp,
          avg_speed: d.avg_speed,
          efficiency_wh_km: d.gross_consumption_wh_km,
          energy_kwh: d.energy_kwh,
          drives: d.drives,
          charges: c[:charges] || 0,
          energy_added_kwh: energy_added,
          total_cost: total_cost,
          cost_per_kwh: cost_per_kwh,
          cost_per_100km: cost_per_100km
        }
      end)

    %{buckets: buckets}
  end
end

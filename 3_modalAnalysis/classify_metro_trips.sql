DO $$
DECLARE 
    quarter INT;
    query TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    ALTER TABLE metro_trips ADD COLUMN IF NOT EXISTS classification VARCHAR(10);

    CREATE INDEX idx_metro_trips_started_at ON metro_trips (started_at);
    CREATE INDEX idx_metro_trips_start_end_station ON metro_trips (start_station_id, end_station_id);
    CREATE INDEX idx_metro_trips_ride_id ON metro_trips (ride_id);

    FOR quarter IN 1..4 LOOP
        -- start and end dates for each quarter
        CASE quarter
            WHEN 1 THEN
                start_date := '2023-01-01';
                end_date := '2023-03-31';
            WHEN 2 THEN
                start_date := '2023-04-01';
                end_date := '2023-06-30';
            WHEN 3 THEN
                start_date := '2023-07-01';
                end_date := '2023-09-30';
            WHEN 4 THEN
                start_date := '2023-10-01';
                end_date := '2023-12-31';
        END CASE;

        ------ compute metro station and metro stop proximity
        query := format('
            CREATE TABLE metro_metro_proximity_q%s AS
            SELECT
                metrobs.station_id AS metro_station_id,
                metrobs.lat AS metro_lat,
                metrobs.lon AS metro_lon,
                metro.stop_id,
                metro.stop_name,
                ST_Distance(metrobs.geom::geography, metro.geom::geography) AS distance_meters
            FROM
                metro_stations metrobs,
                metro_q%s_stops metro
            WHERE
                ST_DWithin(metrobs.geom::geography, metro.geom::geography, 400);
        ', quarter, quarter);
        EXECUTE query;

        ------ compute arrival and depature times in relation to each station
        query := format('
            CREATE TABLE metro_metro_times_q%s AS
            SELECT
                proximity.metro_station_id,
                proximity.stop_id,
                stop_times.trip_id,
                trips.service_id,
                stop_times.arrival_time,
                stop_times.departure_time,
                calendar.monday,
                calendar.tuesday,
                calendar.wednesday,
                calendar.thursday,
                calendar.friday,
                calendar.saturday,
                calendar.sunday
            FROM
                metro_metro_proximity_q%s proximity
            JOIN
                metro_q%s_stop_times stop_times
            ON
                proximity.stop_id = stop_times.stop_id
            JOIN
                metro_q%s_trips trips
            ON
                stop_times.trip_id = trips.trip_id
            JOIN
                metro_q%s_calendar calendar
            ON
                trips.service_id = calendar.service_id;
        ', quarter, quarter, quarter, quarter, quarter);
        EXECUTE query;

        -- create indices
        query := format('
            CREATE INDEX idx_metro_metro_times_start_time_q%s ON metro_metro_times_q%s (metro_station_id, arrival_time);
            CREATE INDEX idx_metro_metro_times_end_time_q%s ON metro_metro_times_q%s (metro_station_id, departure_time);
            CREATE INDEX idx_metro_metro_times_day_q%s ON metro_metro_times_q%s (sunday, monday, tuesday, wednesday, thursday, friday, saturday);
        ', quarter, quarter, quarter, quarter, quarter, quarter);
        EXECUTE query;

        ------ begin classification of trips as MI-FLM, MI-LM, MI-FM, MS or none
        query := format('
            WITH date_to_quarter AS (
                SELECT
                    ride_id,
                    start_station_id,
                    end_station_id,
                    started_at,
                    ended_at,
                    EXTRACT(DOW FROM started_at) AS day_of_week,
                    EXTRACT(EPOCH FROM (ended_at - started_at)) / 60 AS duration_minutes
                FROM metro_trips
                WHERE started_at::DATE BETWEEN ''%s'' AND ''%s''
            )
            UPDATE metro_trips
            SET classification = CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM metro_metro_times_q%s AS start_times,
                         metro_metro_times_q%s AS end_times
                    WHERE date_to_quarter.start_station_id = start_times.metro_station_id
                    AND date_to_quarter.end_station_id = end_times.metro_station_id
                    AND date_to_quarter.started_at BETWEEN 
                        (date_trunc(''day'', date_to_quarter.started_at) + start_times.arrival_time) 
                        AND 
                        (date_trunc(''day'', date_to_quarter.started_at) + start_times.arrival_time + INTERVAL ''10 minutes'')
                    AND date_to_quarter.ended_at BETWEEN 
                        (date_trunc(''day'', date_to_quarter.ended_at) + end_times.departure_time - INTERVAL ''10 minutes'') 
                        AND 
                        (date_trunc(''day'', date_to_quarter.ended_at) + end_times.departure_time)
                    AND date_to_quarter.duration_minutes <= 10
                    AND CASE
                        WHEN date_to_quarter.day_of_week = 0 THEN start_times.sunday
                        WHEN date_to_quarter.day_of_week = 1 THEN start_times.monday
                        WHEN date_to_quarter.day_of_week = 2 THEN start_times.tuesday
                        WHEN date_to_quarter.day_of_week = 3 THEN start_times.wednesday
                        WHEN date_to_quarter.day_of_week = 4 THEN start_times.thursday
                        WHEN date_to_quarter.day_of_week = 5 THEN start_times.friday
                        WHEN date_to_quarter.day_of_week = 6 THEN start_times.saturday
                    END
                    AND CASE
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 0 THEN end_times.sunday
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 1 THEN end_times.monday
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 2 THEN end_times.tuesday
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 3 THEN end_times.wednesday
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 4 THEN end_times.thursday
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 5 THEN end_times.friday
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 6 THEN end_times.saturday
                    END
                ) THEN ''MI-FLM''

                WHEN EXISTS (
                    SELECT 1
                    FROM metro_metro_times_q%s AS start_times,
                        metro_metro_times_q%s AS end_times
                    WHERE date_to_quarter.start_station_id = start_times.metro_station_id
                    AND date_to_quarter.end_station_id = end_times.metro_station_id
                    AND date_to_quarter.ended_at BETWEEN 
                        (date_trunc(''day'', date_to_quarter.ended_at) + end_times.arrival_time - INTERVAL ''10 minutes'') 
                        AND 
                        (date_trunc(''day'', date_to_quarter.ended_at) + end_times.arrival_time + INTERVAL ''10 minutes'')
                    AND CASE
                        WHEN date_to_quarter.day_of_week = 0 THEN start_times.sunday
                        WHEN date_to_quarter.day_of_week = 1 THEN start_times.monday
                        WHEN date_to_quarter.day_of_week = 2 THEN start_times.tuesday
                        WHEN date_to_quarter.day_of_week = 3 THEN start_times.wednesday
                        WHEN date_to_quarter.day_of_week = 4 THEN start_times.thursday
                        WHEN date_to_quarter.day_of_week = 5 THEN start_times.friday
                        WHEN date_to_quarter.day_of_week = 6 THEN start_times.saturday
                    END
                    AND CASE
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 0 THEN end_times.sunday
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 1 THEN end_times.monday
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 2 THEN end_times.tuesday
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 3 THEN end_times.wednesday
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 4 THEN end_times.thursday
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 5 THEN end_times.friday
                        WHEN EXTRACT(DOW FROM date_to_quarter.ended_at) = 6 THEN end_times.saturday
                    END
                ) THEN ''MS''

                WHEN EXISTS (
                    SELECT 1
                    FROM metro_metro_times_q%s AS times
                    WHERE date_to_quarter.start_station_id = times.metro_station_id
                    AND date_to_quarter.started_at BETWEEN 
                        (date_trunc(''day'', date_to_quarter.started_at) + times.arrival_time) 
                        AND 
                        (date_trunc(''day'', date_to_quarter.started_at) + times.arrival_time + INTERVAL ''10 minutes'')
                    AND date_to_quarter.duration_minutes <= 10
                    AND CASE
                        WHEN date_to_quarter.day_of_week = 0 THEN times.sunday
                        WHEN date_to_quarter.day_of_week = 1 THEN times.monday
                        WHEN date_to_quarter.day_of_week = 2 THEN times.tuesday
                        WHEN date_to_quarter.day_of_week = 3 THEN times.wednesday
                        WHEN date_to_quarter.day_of_week = 4 THEN times.thursday
                        WHEN date_to_quarter.day_of_week = 5 THEN times.friday
                        WHEN date_to_quarter.day_of_week = 6 THEN times.saturday
                    END
                ) THEN ''MI-LM''

                WHEN EXISTS (
                    SELECT 1
                    FROM metro_metro_times_q%s AS times
                    WHERE date_to_quarter.end_station_id = times.metro_station_id
                    AND date_to_quarter.ended_at BETWEEN 
                        (date_trunc(''day'', date_to_quarter.ended_at) + times.departure_time - INTERVAL ''10 minutes'') 
                        AND 
                        (date_trunc(''day'', date_to_quarter.ended_at) + times.departure_time)
                    AND date_to_quarter.duration_minutes <= 10
                    AND CASE
                        WHEN date_to_quarter.day_of_week = 0 THEN times.sunday
                        WHEN date_to_quarter.day_of_week = 1 THEN times.monday
                        WHEN date_to_quarter.day_of_week = 2 THEN times.tuesday
                        WHEN date_to_quarter.day_of_week = 3 THEN times.wednesday
                        WHEN date_to_quarter.day_of_week = 4 THEN times.thursday
                        WHEN date_to_quarter.day_of_week = 5 THEN times.friday
                        WHEN date_to_quarter.day_of_week = 6 THEN times.saturday
                    END
                ) THEN ''MI-FM''

                ELSE ''none''
            END
            FROM date_to_quarter
            WHERE metro_trips.ride_id = date_to_quarter.ride_id;
        ', start_date, end_date, quarter, quarter, quarter, quarter, quarter, quarter);
        EXECUTE query;

        RAISE NOTICE 'done with quarter %', quarter;
    END LOOP;
END $$;
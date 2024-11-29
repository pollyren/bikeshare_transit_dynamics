------ compute metro station and metro stop proximity
-- q1
CREATE TABLE metro_metro_proximity_q1 AS
SELECT
    metrobs.station_id AS metro_station_id,
    metrobs.lat AS metro_lat,
    metrobs.lon AS metro_lon,
    metro.stop_id,
    metro.stop_name,
    ST_Distance(metrobs.geom::geography, metro.geom::geography) AS distance_meters
FROM
    metro_stations metrobs,
    metro_q1_stops metro
WHERE
    ST_DWithin(metrobs.geom::geography, metro.geom::geography, 400);

-- q2
CREATE TABLE metro_metro_proximity_q2 AS
SELECT
    metrobs.station_id AS metro_station_id,
    metrobs.lat AS metro_lat,
    metrobs.lon AS metro_lon,
    metro.stop_id,
    metro.stop_name,
    ST_Distance(metrobs.geom::geography, metro.geom::geography) AS distance_meters
FROM
    metro_stations metrobs,
    metro_q2_stops metro
WHERE
    ST_DWithin(metrobs.geom::geography, metro.geom::geography, 400);

-- q3
CREATE TABLE metro_metro_proximity_q3 AS
SELECT
    metrobs.station_id AS metro_station_id,
    metrobs.lat AS metro_lat,
    metrobs.lon AS metro_lon,
    metro.stop_id,
    metro.stop_name,
    ST_Distance(metrobs.geom::geography, metro.geom::geography) AS distance_meters
FROM
    metro_stations metrobs,
    metro_q3_stops metro
WHERE
    ST_DWithin(metrobs.geom::geography, metro.geom::geography, 400);

-- q4
CREATE TABLE metro_metro_proximity_q4 AS
SELECT
    metrobs.station_id AS metro_station_id,
    metrobs.lat AS metro_lat,
    metrobs.lon AS metro_lon,
    metro.stop_id,
    metro.stop_name,
    ST_Distance(metrobs.geom::geography, metro.geom::geography) AS distance_meters
FROM
    metro_stations metrobs,
    metro_q4_stops metro
WHERE
    ST_DWithin(metrobs.geom::geography, metro.geom::geography, 400);

------ compute arrival and depature times in relation to each station
-- q1
CREATE TABLE metro_metro_times_q1 AS
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
    metro_metro_proximity_q1 proximity
JOIN
    metro_q1_stop_times stop_times
ON
    proximity.stop_id = stop_times.stop_id
JOIN
    metro_q1_trips trips
ON
    stop_times.trip_id = trips.trip_id
JOIN
    metro_q1_calendar calendar
ON
    trips.service_id = calendar.service_id;

-- q2
CREATE TABLE metro_metro_times_q2 AS
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
    metro_metro_proximity_q2 proximity
JOIN
    metro_q2_stop_times stop_times
ON
    proximity.stop_id = stop_times.stop_id
JOIN
    metro_q2_trips trips
ON
    stop_times.trip_id = trips.trip_id
JOIN
    metro_q2_calendar calendar
ON
    trips.service_id = calendar.service_id;

-- q3
CREATE TABLE metro_metro_times_q3 AS
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
    metro_metro_proximity_q3 proximity
JOIN
    metro_q3_stop_times stop_times
ON
    proximity.stop_id = stop_times.stop_id
JOIN
    metro_q3_trips trips
ON
    stop_times.trip_id = trips.trip_id
JOIN
    metro_q3_calendar calendar
ON
    trips.service_id = calendar.service_id;

-- q4
CREATE TABLE metro_metro_times_q4 AS
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
    metro_metro_proximity_q4 proximity
JOIN
    metro_q4_stop_times stop_times
ON
    proximity.stop_id = stop_times.stop_id
JOIN
    metro_q4_trips trips
ON
    stop_times.trip_id = trips.trip_id
JOIN
    metro_q4_calendar calendar
ON
    trips.service_id = calendar.service_id;

------ begin classification of trips as MI-FLM, MI-LM, MI-FM, MS or none
ALTER TABLE metro_trips ADD COLUMN classification VARCHAR(10);

UPDATE metro_trips
SET classification = 'none'
WHERE start_station_id = end_station_id;

-- q1
\echo 'starting quarter 1...'
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
    WHERE started_at::DATE BETWEEN '2023-01-01' AND '2023-03-31'
      AND start_station_id != end_station_id
)
UPDATE metro_trips
SET classification = CASE
    -- MI-FLM
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q1 AS start_times,
             metro_metro_times_q1 AS end_times
        WHERE date_to_quarter.start_station_id = start_times.metro_station_id
        AND date_to_quarter.end_station_id = end_times.metro_station_id
        AND date_to_quarter.started_at BETWEEN 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time) 
            AND 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time + INTERVAL '10 minutes')
        AND date_to_quarter.ended_at BETWEEN 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.departure_time - INTERVAL '10 minutes') 
            AND 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.departure_time)
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
    ) THEN 'MI-FLM'

    -- MS
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q1 AS start_times,
             metro_metro_times_q1 AS end_times
        WHERE date_to_quarter.start_station_id = start_times.metro_station_id
        AND date_to_quarter.end_station_id = end_times.metro_station_id
        AND date_to_quarter.started_at BETWEEN 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time) 
            AND 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time + INTERVAL '10 minutes')
        AND date_to_quarter.ended_at BETWEEN 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.arrival_time - INTERVAL '10 minutes') 
            AND 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.arrival_time)
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
    ) THEN 'MS'

    -- MI-LM
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q1 AS times
        WHERE date_to_quarter.start_station_id = times.metro_station_id
          AND date_to_quarter.started_at BETWEEN 
              (date_trunc('day', date_to_quarter.started_at) + times.arrival_time) 
              AND 
              (date_trunc('day', date_to_quarter.started_at) + times.arrival_time + INTERVAL '10 minutes')
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
    ) THEN 'MI-LM'

    -- MI-FM
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q1 AS times
        WHERE date_to_quarter.end_station_id = times.metro_station_id
          AND date_to_quarter.ended_at BETWEEN 
              (date_trunc('day', date_to_quarter.ended_at) + times.departure_time - INTERVAL '10 minutes') 
              AND 
              (date_trunc('day', date_to_quarter.ended_at) + times.departure_time)
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
    ) THEN 'MI-FM'

    -- no matches
    ELSE 'none'
END
FROM date_to_quarter
WHERE metro_trips.ride_id = date_to_quarter.ride_id;
\echo 'done with quarter 1'


-- q2
\echo 'starting quarter 2...'
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
    WHERE started_at::DATE BETWEEN '2023-04-01' AND '2023-06-30'
      AND start_station_id != end_station_id
)
UPDATE metro_trips
SET classification = CASE
    -- MI-FLM
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q2 AS start_times,
             metro_metro_times_q2 AS end_times
        WHERE date_to_quarter.start_station_id = start_times.metro_station_id
        AND date_to_quarter.end_station_id = end_times.metro_station_id
        AND date_to_quarter.started_at BETWEEN 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time) 
            AND 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time + INTERVAL '10 minutes')
        AND date_to_quarter.ended_at BETWEEN 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.departure_time - INTERVAL '10 minutes') 
            AND 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.departure_time)
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
    ) THEN 'MI-FLM'

    -- MS
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q2 AS start_times,
             metro_metro_times_q2 AS end_times
        WHERE date_to_quarter.start_station_id = start_times.metro_station_id
        AND date_to_quarter.end_station_id = end_times.metro_station_id
        AND date_to_quarter.started_at BETWEEN 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time) 
            AND 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time + INTERVAL '10 minutes')
        AND date_to_quarter.ended_at BETWEEN 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.arrival_time - INTERVAL '10 minutes') 
            AND 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.arrival_time)
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
    ) THEN 'MS'

    -- MI-LM
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q2 AS times
        WHERE date_to_quarter.start_station_id = times.metro_station_id
          AND date_to_quarter.started_at BETWEEN 
              (date_trunc('day', date_to_quarter.started_at) + times.arrival_time) 
              AND 
              (date_trunc('day', date_to_quarter.started_at) + times.arrival_time + INTERVAL '10 minutes')
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
    ) THEN 'MI-LM'

    -- MI-FM
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q2 AS times
        WHERE date_to_quarter.end_station_id = times.metro_station_id
          AND date_to_quarter.ended_at BETWEEN 
              (date_trunc('day', date_to_quarter.ended_at) + times.departure_time - INTERVAL '10 minutes') 
              AND 
              (date_trunc('day', date_to_quarter.ended_at) + times.departure_time)
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
    ) THEN 'MI-FM'

    -- no matches
    ELSE 'none'
END
FROM date_to_quarter
WHERE metro_trips.ride_id = date_to_quarter.ride_id;
\echo 'done with quarter 2'


-- q3
\echo 'starting quarter 3...'
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
    WHERE started_at::DATE BETWEEN '2023-07-01' AND '2023-09-30'
      AND start_station_id != end_station_id
)
UPDATE metro_trips
SET classification = CASE
    -- MI-FLM
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q3 AS start_times,
             metro_metro_times_q3 AS end_times
        WHERE date_to_quarter.start_station_id = start_times.metro_station_id
        AND date_to_quarter.end_station_id = end_times.metro_station_id
        AND date_to_quarter.started_at BETWEEN 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time) 
            AND 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time + INTERVAL '10 minutes')
        AND date_to_quarter.ended_at BETWEEN 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.departure_time - INTERVAL '10 minutes') 
            AND 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.departure_time)
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
    ) THEN 'MI-FLM'

    -- MS
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q3 AS start_times,
             metro_metro_times_q3 AS end_times
        WHERE date_to_quarter.start_station_id = start_times.metro_station_id
        AND date_to_quarter.end_station_id = end_times.metro_station_id
        AND date_to_quarter.started_at BETWEEN 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time) 
            AND 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time + INTERVAL '10 minutes')
        AND date_to_quarter.ended_at BETWEEN 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.arrival_time - INTERVAL '10 minutes') 
            AND 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.arrival_time)
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
    ) THEN 'MS'

    -- MI-LM
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q3 AS times
        WHERE date_to_quarter.start_station_id = times.metro_station_id
          AND date_to_quarter.started_at BETWEEN 
              (date_trunc('day', date_to_quarter.started_at) + times.arrival_time) 
              AND 
              (date_trunc('day', date_to_quarter.started_at) + times.arrival_time + INTERVAL '10 minutes')
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
    ) THEN 'MI-LM'

    -- MI-FM
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q3 AS times
        WHERE date_to_quarter.end_station_id = times.metro_station_id
          AND date_to_quarter.ended_at BETWEEN 
              (date_trunc('day', date_to_quarter.ended_at) + times.departure_time - INTERVAL '10 minutes') 
              AND 
              (date_trunc('day', date_to_quarter.ended_at) + times.departure_time)
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
    ) THEN 'MI-FM'

    -- no matches
    ELSE 'none'
END
FROM date_to_quarter
WHERE metro_trips.ride_id = date_to_quarter.ride_id;
\echo 'done with quarter 3'


-- q4
\echo 'starting quarter 4...'
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
    WHERE started_at::DATE BETWEEN '2023-10-01' AND '2023-12-31'
      AND start_station_id != end_station_id
)
UPDATE metro_trips
SET classification = CASE
    -- MI-FLM
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q4 AS start_times,
             metro_metro_times_q4 AS end_times
        WHERE date_to_quarter.start_station_id = start_times.metro_station_id
        AND date_to_quarter.end_station_id = end_times.metro_station_id
        AND date_to_quarter.started_at BETWEEN 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time) 
            AND 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time + INTERVAL '10 minutes')
        AND date_to_quarter.ended_at BETWEEN 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.departure_time - INTERVAL '10 minutes') 
            AND 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.departure_time)
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
    ) THEN 'MI-FLM'

    -- MS
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q4 AS start_times,
             metro_metro_times_q4 AS end_times
        WHERE date_to_quarter.start_station_id = start_times.metro_station_id
        AND date_to_quarter.end_station_id = end_times.metro_station_id
        AND date_to_quarter.started_at BETWEEN 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time) 
            AND 
            (date_trunc('day', date_to_quarter.started_at) + start_times.arrival_time + INTERVAL '10 minutes')
        AND date_to_quarter.ended_at BETWEEN 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.arrival_time - INTERVAL '10 minutes') 
            AND 
            (date_trunc('day', date_to_quarter.ended_at) + end_times.arrival_time)
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
    ) THEN 'MS'

    -- MI-LM
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q4 AS times
        WHERE date_to_quarter.start_station_id = times.metro_station_id
          AND date_to_quarter.started_at BETWEEN 
              (date_trunc('day', date_to_quarter.started_at) + times.arrival_time) 
              AND 
              (date_trunc('day', date_to_quarter.started_at) + times.arrival_time + INTERVAL '10 minutes')
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
    ) THEN 'MI-LM'

    -- MI-FM
    WHEN EXISTS (
        SELECT 1
        FROM metro_metro_times_q4 AS times
        WHERE date_to_quarter.end_station_id = times.metro_station_id
          AND date_to_quarter.ended_at BETWEEN 
              (date_trunc('day', date_to_quarter.ended_at) + times.departure_time - INTERVAL '10 minutes') 
              AND 
              (date_trunc('day', date_to_quarter.ended_at) + times.departure_time)
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
    ) THEN 'MI-FM'

    -- no matches
    ELSE 'none'
END
FROM date_to_quarter
WHERE metro_trips.ride_id = date_to_quarter.ride_id;
\echo 'done with quarter 4'

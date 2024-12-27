INSERT INTO divvy_trips (
    ride_id, 
    rideable_type, 
    started_at, 
    ended_at, 
    start_station_id, 
    end_station_id, 
    start_lat, 
    start_lng, 
    end_lat, 
    end_lng, 
    member_casual, 
    start_geom, 
    end_geom
)
SELECT 
    ride_id,
    rideable_type,
    started_at,
    ended_at,
    start_station_id,
    end_station_id,
    start_lat,
    start_lng,
    end_lat,
    end_lng,
    member_casual,
    ST_SetSRID(ST_MakePoint(start_lng, start_lat), 4326),
    ST_SetSRID(ST_MakePoint(end_lng, end_lat), 4326)
FROM divvy_trips_raw
WHERE 
    -- consider only trips for this year
    EXTRACT(YEAR FROM started_at) = :trip_year
    AND EXTRACT(YEAR FROM ended_at) = :trip_year
    -- ensure ride duration is between 1 and 90 minutes
    AND EXTRACT(EPOCH FROM (ended_at - started_at)) / 60 > 1
    AND EXTRACT(EPOCH FROM (ended_at - started_at)) / 60 < 90
    -- ensure ride starts and end at a station
    AND start_station_id IS NOT NULL AND start_station_id <> ''
    AND end_station_id IS NOT NULL AND end_station_id <> ''
    -- ensure ride does not start and end at same station
    AND start_station_id != end_station_id;

INSERT INTO citi_trips (
    ride_id, 
    rideable_type, 
    started_at, 
    ended_at, 
    start_station_id, 
    end_station_id, 
    start_lat, 
    start_lng, 
    end_lat, 
    end_lng, 
    member_casual, 
    start_geom, 
    end_geom
)
SELECT 
    ride_id,
    rideable_type,
    started_at,
    ended_at,
    start_station_id,
    end_station_id,
    start_lat,
    start_lng,
    end_lat,
    end_lng,
    member_casual,
    ST_SetSRID(ST_MakePoint(start_lng, start_lat), 4326),
    ST_SetSRID(ST_MakePoint(end_lng, end_lat), 4326)
FROM citi_trips_raw
WHERE 
    -- consider only trips for this year
    EXTRACT(YEAR FROM started_at) = :trip_year
    AND EXTRACT(YEAR FROM ended_at) = :trip_year
    -- ensure ride duration is between 1 and 90 minutes
    AND EXTRACT(EPOCH FROM (ended_at - started_at)) / 60 > 1
    AND EXTRACT(EPOCH FROM (ended_at - started_at)) / 60 < 90
    -- ensure ride starts and end at a station
    AND start_station_id IS NOT NULL AND start_station_id <> ''
    AND end_station_id IS NOT NULL AND end_station_id <> ''
    -- ensure ride does not start and end at same station
    AND start_station_id != end_station_id;

INSERT INTO metro_trips (
    ride_id, 
    rideable_type, 
    started_at, 
    ended_at, 
    start_station_id, 
    end_station_id, 
    start_lat, 
    start_lng, 
    end_lat, 
    end_lng, 
    member_casual, 
    start_geom, 
    end_geom
)
SELECT 
    trip_id AS ride_id,
    bike_type AS rideable_type,
    start_time AS started_at,
    end_time AS ended_at,
    start_station AS start_station_id,
    end_station AS end_station_id,
    start_lat,
    start_lon AS start_lng,
    end_lat, 
    end_lon AS end_lng,
    passholder_type AS member_casual,
    ST_SetSRID(ST_MakePoint(start_lon, start_lat), 4326),
    ST_SetSRID(ST_MakePoint(end_lon, end_lat), 4326)
FROM metro_trips_raw
WHERE 
    -- consider only trips for this year
    EXTRACT(YEAR FROM start_time) = :trip_year
    AND EXTRACT(YEAR FROM end_time) = :trip_year
    -- ensure ride duration is between 1 and 90 minutes
    AND EXTRACT(EPOCH FROM (end_time - start_time)) / 60 > 1
    AND EXTRACT(EPOCH FROM (end_time - start_time)) / 60 < 90
    -- ensure ride starts and end at a station
    AND start_station IS NOT NULL AND start_station <> ''
    AND end_station IS NOT NULL AND end_station <> ''
    -- ensure ride does not start and end at same station
    AND start_station != end_station;

-- ensure station ids exist in stations data
DELETE FROM divvy_trips t
WHERE NOT EXISTS (
    SELECT 1
    FROM divvy_stations s
    WHERE s.station_id = t.start_station_id
);
DELETE FROM divvy_trips t
WHERE NOT EXISTS (
    SELECT 1
    FROM divvy_stations s
    WHERE s.station_id = t.end_station_id
);

DELETE FROM citi_trips t
WHERE NOT EXISTS (
    SELECT 1
    FROM citi_stations s
    WHERE s.station_id = t.start_station_id
);
DELETE FROM citi_trips t
WHERE NOT EXISTS (
    SELECT 1
    FROM citi_stations s
    WHERE s.station_id = t.end_station_id
);

DELETE FROM metro_trips t
WHERE NOT EXISTS (
    SELECT 1
    FROM metro_stations s
    WHERE s.station_id = t.start_station_id
);
DELETE FROM metro_trips t
WHERE NOT EXISTS (
    SELECT 1
    FROM metro_stations s
    WHERE s.station_id = t.end_station_id
);

-- some basic pre-filtering stats and cleanup raw tables
\echo 'divvy'
SELECT COUNT(*) FROM divvy_trips_raw;

\echo 'citi'
SELECT COUNT(*) FROM citi_trips_raw;

\echo 'metro'
SELECT COUNT(*) FROM metro_trips_raw;

DROP TABLE divvy_trips_raw;
DROP TABLE citi_trips_raw;
DROP TABLE metro_trips_raw;
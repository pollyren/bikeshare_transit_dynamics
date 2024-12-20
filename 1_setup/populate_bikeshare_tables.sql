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
    -- ensure ride duration is between 1 and 90 minutes
    EXTRACT(EPOCH FROM (ended_at - started_at)) / 60 > 1
    AND EXTRACT(EPOCH FROM (ended_at - started_at)) / 60 < 90
    -- ensure ride starts and end at a station
    AND start_station_id IS NOT NULL AND start_station_id <> ''
    AND end_station_id IS NOT NULL AND end_station_id <> '';

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
    -- ensure ride duration is between 1 and 90 minutes
    EXTRACT(EPOCH FROM (ended_at - started_at)) / 60 > 1
    AND EXTRACT(EPOCH FROM (ended_at - started_at)) / 60 < 90
    -- ensure ride starts and end at a station
    AND start_station_id IS NOT NULL AND start_station_id <> ''
    AND end_station_id IS NOT NULL AND end_station_id <> '';

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
    -- ensure ride duration is between 1 and 90 minutes
    EXTRACT(EPOCH FROM (end_time - start_time)) / 60 > 1
    AND EXTRACT(EPOCH FROM (end_time - start_time)) / 60 < 90
    -- ensure ride starts and end at a station
    AND start_station IS NOT NULL AND start_station <> ''
    AND end_station IS NOT NULL AND end_station <> '';

DROP TABLE divvy_trips_raw;
DROP TABLE citi_trips_raw;
DROP TABLE metro_trips_raw;
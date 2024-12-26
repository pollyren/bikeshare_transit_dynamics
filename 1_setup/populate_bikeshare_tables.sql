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
    r.ride_id,
    r.rideable_type,
    r.started_at,
    r.ended_at,
    r.start_station_id,
    r.end_station_id,
    r.start_lat,
    r.start_lng,
    r.end_lat,
    r.end_lng,
    r.member_casual,
    ST_SetSRID(ST_MakePoint(r.start_lng, r.start_lat), 4326),
    ST_SetSRID(ST_MakePoint(r.end_lng, r.end_lat), 4326)
FROM divvy_trips_raw r
-- ensure station ids exist in stations data
JOIN divvy_stations s1 ON r.start_station_id = s1.station_id
JOIN divvy_stations s2 ON r.end_station_id = s2.station_id
WHERE 
    -- consider only trips for this year
    EXTRACT(YEAR FROM r.started_at) = :trip_year
    AND EXTRACT(YEAR FROM r.ended_at) = :trip_year
    -- ensure ride duration is between 1 and 90 minutes
    AND EXTRACT(EPOCH FROM (r.ended_at - r.started_at)) / 60 > 1
    AND EXTRACT(EPOCH FROM (r.ended_at - r.started_at)) / 60 < 90
    -- ensure ride does not start and end at the same station
    AND r.start_station_id != r.end_station_id;

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
    r.ride_id,
    r.rideable_type,
    r.started_at,
    r.ended_at,
    r.start_station_id,
    r.end_station_id,
    r.start_lat,
    r.start_lng,
    r.end_lat,
    r.end_lng,
    r.member_casual,
    ST_SetSRID(ST_MakePoint(r.start_lng, r.start_lat), 4326),
    ST_SetSRID(ST_MakePoint(r.end_lng, r.end_lat), 4326)
FROM citi_trips_raw r
-- ensure station ids exist in stations data
JOIN citi_stations s1 ON r.start_station_id = s1.station_id
JOIN citi_stations s2 ON r.end_station_id = s2.station_id
WHERE 
    -- consider only trips for this year
    EXTRACT(YEAR FROM r.started_at) = :trip_year
    AND EXTRACT(YEAR FROM r.ended_at) = :trip_year
    -- ensure ride duration is between 1 and 90 minutes
    AND EXTRACT(EPOCH FROM (r.ended_at - r.started_at)) / 60 > 1
    AND EXTRACT(EPOCH FROM (r.ended_at - r.started_at)) / 60 < 90
    -- ensure ride does not start and end at the same station
    AND r.start_station_id != r.end_station_id;

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
    r.ride_id,
    r.rideable_type,
    r.started_at,
    r.ended_at,
    r.start_station_id,
    r.end_station_id,
    r.start_lat,
    r.start_lng,
    r.end_lat,
    r.end_lng,
    r.member_casual,
    ST_SetSRID(ST_MakePoint(r.start_lng, r.start_lat), 4326),
    ST_SetSRID(ST_MakePoint(r.end_lng, r.end_lat), 4326)
FROM metro_trips_raw r
-- ensure station ids exist in stations data
JOIN metro_stations s1 ON r.start_station_id = s1.station_id
JOIN metro_stations s2 ON r.end_station_id = s2.station_id
WHERE 
    -- consider only trips for this year
    EXTRACT(YEAR FROM r.started_at) = :trip_year
    AND EXTRACT(YEAR FROM r.ended_at) = :trip_year
    -- ensure ride duration is between 1 and 90 minutes
    AND EXTRACT(EPOCH FROM (r.ended_at - r.started_at)) / 60 > 1
    AND EXTRACT(EPOCH FROM (r.ended_at - r.started_at)) / 60 < 90
    -- ensure ride does not start and end at the same station
    AND r.start_station_id != r.end_station_id;

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
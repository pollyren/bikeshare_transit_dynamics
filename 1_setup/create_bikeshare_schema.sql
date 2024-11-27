-- divvy
CREATE TABLE IF NOT EXISTS divvy_trips_raw (
    ride_id TEXT,
    rideable_type VARCHAR(20),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    start_station_name TEXT,
    start_station_id TEXT,
    end_station_name TEXT,
    end_station_id TEXT,
    start_lat FLOAT,
    start_lng FLOAT,
    end_lat FLOAT,
    end_lng FLOAT,
    member_casual VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS divvy_trips (
    ride_id TEXT,
    rideable_type VARCHAR(20),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    start_station_id TEXT,
    end_station_id TEXT,
    start_lat FLOAT,
    start_lng FLOAT,
    end_lat FLOAT,
    end_lng FLOAT,
    member_casual VARCHAR(20),
    start_geom GEOMETRY(Point, 4326),
    end_geom GEOMETRY(Point, 4326)
);

-- citibike
CREATE TABLE IF NOT EXISTS citi_trips_raw (
    ride_id TEXT,
    rideable_type VARCHAR(20),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    start_station_name TEXT,
    start_station_id TEXT,
    end_station_name TEXT,
    end_station_id TEXT,
    start_lat FLOAT,
    start_lng FLOAT,
    end_lat FLOAT,
    end_lng FLOAT,
    member_casual VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS citi_trips (
    ride_id TEXT,
    rideable_type VARCHAR(20),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    start_station_id TEXT,
    end_station_id TEXT,
    start_lat FLOAT,
    start_lng FLOAT,
    end_lat FLOAT,
    end_lng FLOAT,
    member_casual VARCHAR(20),
    start_geom GEOMETRY(Point, 4326),
    end_geom GEOMETRY(Point, 4326)
);

-- metro bikeshare
CREATE TABLE IF NOT EXISTS metro_trips_raw (
    trip_id TEXT,
    duration INTEGER,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    start_station TEXT,
    start_lat FLOAT,
    start_lon FLOAT,
    end_station TEXT,
    end_lat FLOAT,
    end_lon FLOAT,
    bike_id TEXT,
    plan_duration INTEGER,
    trip_route_category TEXT,
    passholder_type TEXT,
    bike_type TEXT
);

CREATE TABLE IF NOT EXISTS metro_trips (
    ride_id TEXT,
    rideable_type VARCHAR(20),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    start_station_id TEXT,
    end_station_id TEXT,
    start_lat FLOAT,
    start_lng FLOAT,
    end_lat FLOAT,
    end_lng FLOAT,
    member_casual VARCHAR(20),
    start_geom GEOMETRY(Point, 4326),
    end_geom GEOMETRY(Point, 4326)
);
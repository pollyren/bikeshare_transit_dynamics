-- trip counts
\echo '=== TRIP COUNTS ==='
SELECT 'divvy' AS dataset, COUNT(*) AS trip_count FROM divvy_trips;
SELECT 'citi' AS dataset, COUNT(*) AS trip_count FROM citi_trips;
SELECT 'metro' AS dataset, COUNT(*) AS trip_count FROM metro_trips;


-- most popular start station
\echo '=== POPULAR START STATIONS ==='
SELECT 
    'divvy' AS dataset,
    divvy_stations.name AS station,
    COUNT(*) AS trip_count 
FROM divvy_trips 
LEFT JOIN divvy_stations 
ON divvy_trips.start_station_id = divvy_stations.station_id
GROUP BY divvy_stations.name
ORDER BY trip_count DESC
LIMIT 10;

SELECT 
    'citi' AS dataset,
    citi_stations.name AS station,
    COUNT(*) AS trip_count 
FROM citi_trips 
LEFT JOIN citi_stations 
ON citi_trips.start_station_id = citi_stations.station_id
GROUP BY citi_stations.name
ORDER BY trip_count DESC
LIMIT 10;

SELECT 
    'metro' AS dataset,
    metro_stations.name AS station,
    COUNT(*) AS trip_count 
FROM metro_trips 
LEFT JOIN metro_stations 
ON metro_trips.start_station_id = metro_stations.station_id
GROUP BY metro_stations.name
ORDER BY trip_count DESC
LIMIT 10;


-- most popular end station
\echo '=== POPULAR END STATIONS ==='
SELECT 
    'divvy' AS dataset,
    divvy_stations.name AS station,
    COUNT(*) AS trip_count 
FROM divvy_trips 
LEFT JOIN divvy_stations 
ON divvy_trips.end_station_id = divvy_stations.station_id
GROUP BY divvy_stations.name
ORDER BY trip_count DESC
LIMIT 10;

SELECT 
    'citi' AS dataset,
    citi_stations.name AS station,
    COUNT(*) AS trip_count 
FROM citi_trips 
LEFT JOIN citi_stations 
ON citi_trips.end_station_id = citi_stations.station_id
GROUP BY citi_stations.name
ORDER BY trip_count DESC
LIMIT 10;

SELECT 
    'metro' AS dataset,
    metro_stations.name AS station,
    COUNT(*) AS trip_count 
FROM metro_trips 
LEFT JOIN metro_stations 
ON metro_trips.end_station_id = metro_stations.station_id
GROUP BY metro_stations.name
ORDER BY trip_count DESC
LIMIT 10;


-- member-casual split
\echo '=== MEMBER / CASUAL COUNTS ==='
SELECT 'divvy' AS dataset, member_casual, COUNT(*) AS cnt 
FROM divvy_trips 
GROUP BY member_casual
ORDER BY cnt DESC;

SELECT 'citi' AS dataset, member_casual, COUNT(*) AS cnt 
FROM citi_trips 
GROUP BY member_casual
ORDER BY cnt DESC;

SELECT 'metro' AS dataset, member_casual, COUNT(*) AS cnt 
FROM metro_trips 
GROUP BY member_casual
ORDER BY cnt DESC;


-- bike type split
\echo '=== BIKE TYPE COUNTS ==='
SELECT 'divvy' AS dataset, rideable_type, COUNT(*) AS cnt 
FROM divvy_trips 
GROUP BY rideable_type
ORDER BY cnt DESC;

SELECT 'citi' AS dataset, rideable_type, COUNT(*) AS cnt 
FROM citi_trips 
GROUP BY rideable_type
ORDER BY cnt DESC;

SELECT 'metro' AS dataset, rideable_type, COUNT(*) AS cnt 
FROM metro_trips 
GROUP BY rideable_type
ORDER BY cnt DESC;
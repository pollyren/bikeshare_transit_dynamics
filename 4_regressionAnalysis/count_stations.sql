-- count the number of bikeshare docks and transit stops per tract
ALTER TABLE census_tracts ADD COLUMN IF NOT EXISTS dock_count INTEGER;
ALTER TABLE census_tracts ADD COLUMN IF NOT EXISTS stop_count INTEGER;

-- counts the number of divvy / citi / metro bikeshare stations in each census tract
UPDATE census_tracts c
SET dock_count = subquery.station_count
FROM (
    SELECT
        c.geoid,
        COUNT(DISTINCT s.station_id) AS station_count
    FROM census_tracts c
    LEFT JOIN divvy_stations s
    ON ST_Contains(c.geom, s.geom)
    GROUP BY c.geoid
) AS subquery
WHERE c.geoid = subquery.geoid
  AND station_count > 0;

UPDATE census_tracts c
SET dock_count = subquery.station_count
FROM (
    SELECT
        c.geoid,
        COUNT(DISTINCT s.station_id) AS station_count
    FROM census_tracts c
    LEFT JOIN citi_stations s
    ON ST_Contains(c.geom, s.geom)
    GROUP BY c.geoid
) AS subquery
WHERE c.geoid = subquery.geoid
  AND station_count > 0;

UPDATE census_tracts c
SET dock_count = subquery.station_count
FROM (
    SELECT
        c.geoid,
        COUNT(DISTINCT s.station_id) AS station_count
    FROM census_tracts c
    LEFT JOIN metro_stations s
    ON ST_Contains(c.geom, s.geom)
    GROUP BY c.geoid
) AS subquery
WHERE c.geoid = subquery.geoid
  AND station_count > 0;


-- counts the number of cta / mta / metro transit stations in each census tract
-- only use q1 stops to prevent multiple counting
UPDATE census_tracts c
SET stop_count = subquery.station_count
FROM (
    SELECT
        c.geoid,
        COUNT(DISTINCT s.stop_id) AS station_count
    FROM census_tracts c
    LEFT JOIN cta_q1_stops s
    ON ST_Contains(c.geom, s.geom)
    GROUP BY c.geoid
) AS subquery
WHERE c.geoid = subquery.geoid
  AND station_count > 0;

UPDATE census_tracts c
SET stop_count = subquery.station_count
FROM (
    SELECT
        c.geoid,
        COUNT(DISTINCT s.stop_id) AS station_count
    FROM census_tracts c
    LEFT JOIN mta_q1_stops s
    ON ST_Contains(c.geom, s.geom)
    GROUP BY c.geoid
) AS subquery
WHERE c.geoid = subquery.geoid
  AND station_count > 0;

UPDATE census_tracts c
SET stop_count = subquery.station_count
FROM (
    SELECT
        c.geoid,
        COUNT(DISTINCT s.stop_id) AS station_count
    FROM census_tracts c
    LEFT JOIN metro_q1_stops s
    ON ST_Contains(c.geom, s.geom)
    GROUP BY c.geoid
) AS subquery
WHERE c.geoid = subquery.geoid
  AND station_count > 0;


-- finally, join the station counts to the aggregate dataset for regression
DO $$
DECLARE
    target_table TEXT;
BEGIN
    FOREACH target_table IN ARRAY ARRAY[
        'divvy_trips_aggregates_start',
        'divvy_trips_aggregates_end',
        'citi_trips_aggregates_start',
        'citi_trips_aggregates_end',
        'metro_trips_aggregates_start',
        'metro_trips_aggregates_end'
    ]
    LOOP
        EXECUTE format(
            'ALTER TABLE %I ADD COLUMN IF NOT EXISTS dock_count INTEGER,
                            ADD COLUMN IF NOT EXISTS stop_count INTEGER;',
            target_table
        );

        EXECUTE format(
            'UPDATE %I AS t
             SET dock_count = c.dock_count,
                 stop_count = c.stop_count
             FROM census_tracts AS c
             WHERE t.tract = c.geoid;',
            target_table
        );
    END LOOP;
END $$;
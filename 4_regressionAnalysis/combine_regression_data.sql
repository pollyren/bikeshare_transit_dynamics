
-- standardise geoid for joining, only keep state, county, tract
ALTER TABLE latch_2017 RENAME COLUMN geocode TO geo_id;

UPDATE latch_2017 SET geo_id = LPAD(RIGHT(geo_id, 11), 11, '0');
UPDATE acs5y2023_socioeconomic SET geo_id = LPAD(RIGHT(geo_id, 11), 11, '0');
UPDATE acs5y2023_employment SET geo_id = LPAD(RIGHT(geo_id, 11), 11, '0');
UPDATE acs5y2023_demographic SET geo_id = LPAD(RIGHT(geo_id, 11), 11, '0');
UPDATE acs5y2023_housing SET geo_id = LPAD(RIGHT(geo_id, 11), 11, '0');

-- aggregate counts in wac data from block level to tract level
CREATE TABLE ca_wac_2022 AS
SELECT
    LEFT(geocode, 11) AS census_tract,
    SUM(c000::INTEGER) AS c000
FROM ca_wac_S000_JT00_2022
WHERE c000 ~ '^[0-9]+$'
GROUP BY census_tract;

CREATE TABLE il_wac_2022 AS
SELECT
    LEFT(geocode, 11) AS census_tract,
    SUM(c000::INTEGER) AS c000
FROM il_wac_S000_JT00_2022
WHERE c000 ~ '^[0-9]+$'
GROUP BY census_tract;

CREATE TABLE ny_wac_2022 AS
SELECT
    LEFT(geocode, 11) AS census_tract,
    SUM(c000::INTEGER) AS c000
FROM ny_wac_S000_JT00_2022
WHERE c000 ~ '^[0-9]+$'
GROUP BY census_tract;

DROP TABLE ca_wac_S000_JT00_2022;
DROP TABLE il_wac_S000_JT00_2022;
DROP TABLE ny_wac_S000_JT00_2022;


-- function to join regression data to bikeshare tables
CREATE OR REPLACE FUNCTION join_regression_data(target_table TEXT)
RETURNS VOID AS
$$
BEGIN
    -- add columns for regression data
    EXECUTE format(
        'ALTER TABLE %I
        ADD COLUMN IF NOT EXISTS median_age FLOAT,
        ADD COLUMN IF NOT EXISTS housing_units INT,
        ADD COLUMN IF NOT EXISTS prop_commute_drove FLOAT,
        ADD COLUMN IF NOT EXISTS prop_commute_carpooled FLOAT,
        ADD COLUMN IF NOT EXISTS prop_commute_pubtransit FLOAT,
        ADD COLUMN IF NOT EXISTS prop_commute_walked FLOAT,
        ADD COLUMN IF NOT EXISTS mean_commute_time FLOAT,
        ADD COLUMN IF NOT EXISTS median_household_income INT,
        ADD COLUMN IF NOT EXISTS unemployment_rate FLOAT,
        ADD COLUMN IF NOT EXISTS prop_no_vehicles FLOAT,
        ADD COLUMN IF NOT EXISTS avg_household_size FLOAT,
        ADD COLUMN IF NOT EXISTS households_with_children INT,
        ADD COLUMN IF NOT EXISTS prop_hs_grad FLOAT,
        ADD COLUMN IF NOT EXISTS prop_college_grad FLOAT,
        ADD COLUMN IF NOT EXISTS prop_same_house FLOAT,
        ADD COLUMN IF NOT EXISTS prop_internet_subscription FLOAT,
        ADD COLUMN IF NOT EXISTS urban_group VARCHAR(10),
        ADD COLUMN IF NOT EXISTS avg_vehicle_miles FLOAT,
        ADD COLUMN IF NOT EXISTS num_streets INT,
        ADD COLUMN IF NOT EXISTS prop_prim_sec_roads FLOAT,
        ADD COLUMN IF NOT EXISTS intersection_density FLOAT,
        ADD COLUMN IF NOT EXISTS street_network_density FLOAT,
        ADD COLUMN IF NOT EXISTS connected_node_ratio FLOAT,
        ADD COLUMN IF NOT EXISTS avg_traffic FLOAT,
        ADD COLUMN IF NOT EXISTS num_intersections INT,
        ADD COLUMN IF NOT EXISTS num_jobs INT;',
        target_table
    );

    -- actually insert the data
    -- acs demographic
    EXECUTE format(
        'UPDATE %I AS t
        SET median_age = CASE
                            WHEN d.dp05_0018e ~ ''^[0-9]+(\.[0-9]+)?$'' THEN d.dp05_0018e::FLOAT
                            ELSE NULL
                        END,
            housing_units = CASE
                            WHEN d.dp05_0091e ~ ''^[0-9]+$'' THEN d.dp05_0091e::INTEGER
                            ELSE NULL
                        END
        FROM acs5y2023_demographic AS d
        WHERE t.tract = d.geo_id;',
        target_table
    );

    -- acs employment
    EXECUTE format(
        'UPDATE %I AS t
        SET prop_commute_drove = CASE
                                    WHEN d.dp03_0019e ~ ''^[0-9]+$'' THEN d.dp03_0019e::FLOAT / NULLIF(d.dp03_0018e, ''0'')::INTEGER
                                    ELSE NULL
                                END,
            prop_commute_carpooled = CASE
                                    WHEN d.dp03_0020e ~ ''^[0-9]+$'' THEN d.dp03_0020e::FLOAT / NULLIF(d.dp03_0018e, ''0'')::INTEGER
                                    ELSE NULL
                                END,
            prop_commute_pubtransit = CASE
                                    WHEN d.dp03_0021e ~ ''^[0-9]+$'' THEN d.dp03_0021e::FLOAT / NULLIF(d.dp03_0018e, ''0'')::INTEGER
                                    ELSE NULL
                                END,
            prop_commute_walked = CASE
                                    WHEN d.dp03_0022e ~ ''^[0-9]+$'' THEN d.dp03_0022e::FLOAT / NULLIF(d.dp03_0018e, ''0'')::INTEGER
                                    ELSE NULL
                                END,
            mean_commute_time = CASE
                                    WHEN d.dp03_0025e ~ ''^[0-9]+(\.[0-9]+)?$'' THEN d.dp03_0025e::FLOAT
                                    ELSE NULL
                                END,
            median_household_income = CASE
                                        WHEN d.dp03_0062e ~ ''^[0-9]+(\.[0-9]+)?$'' THEN d.dp03_0062e::FLOAT
                                        ELSE NULL
                                    END,
            unemployment_rate = CASE
                                    WHEN d.dp03_0009pe ~ ''^[0-9]+(\.[0-9]+)?$'' THEN d.dp03_0009pe::FLOAT
                                    ELSE NULL
                                END
        FROM acs5y2023_employment AS d
        WHERE t.tract = d.geo_id;',
        target_table
    );

    -- acs housing
    EXECUTE format(
        'UPDATE %I AS t
        SET prop_no_vehicles = CASE
                                    WHEN d.s2504_c01_027e ~ ''^[0-9]+(\.[0-9]+)?$'' THEN d.s2504_c01_027e::FLOAT
                                    ELSE NULL
                                END
        FROM acs5y2023_housing AS d
        WHERE t.tract = d.geo_id;',
        target_table
    );

    -- acs socioeconomic
    EXECUTE format(
        'UPDATE %I AS t
        SET avg_household_size = CASE
                                    WHEN d.dp02_0016e ~ ''^[0-9]+(\.[0-9]+)?$'' THEN d.dp02_0016e::FLOAT
                                    ELSE NULL
                                END,
            households_with_children = CASE
                                        WHEN d.dp02_0022e ~ ''^[0-9]+$'' THEN d.dp02_0022e::INTEGER
                                        ELSE NULL
                                    END,
            prop_hs_grad = CASE
                            WHEN d.dp02_0067e ~ ''^[0-9]+$'' THEN d.dp02_0067e::FLOAT / NULLIF(d.dp02_0059e, ''0'')::INTEGER
                            ELSE NULL
                        END,
            prop_college_grad = CASE
                            WHEN d.dp02_0068e ~ ''^[0-9]+$'' THEN d.dp02_0068e::FLOAT / NULLIF(d.dp02_0059e, ''0'')::INTEGER
                            ELSE NULL
                        END,
            prop_same_house = CASE
                            WHEN d.dp02_0080e ~ ''^[0-9]+$'' THEN d.dp02_0080e::FLOAT / NULLIF(d.dp02_0079e, ''0'')::INTEGER
                            ELSE NULL
                        END,
            prop_internet_subscription = CASE
                            WHEN d.dp02_0154e ~ ''^[0-9]+$'' THEN d.dp02_0154e::FLOAT / NULLIF(d.dp02_0152e, ''0'')::INTEGER
                            ELSE NULL
                        END
        FROM acs5y2023_socioeconomic AS d
        WHERE t.tract = d.geo_id;',
        target_table
    );

    -- latch data
    EXECUTE format(
        'UPDATE %I AS t
        SET urban_group = NULLIF(d.urban_group, ''-''),
            avg_vehicle_miles = NULLIF(d.est_vmiles, ''-'')::FLOAT
        FROM latch_2017 AS d
        WHERE t.tract = d.geo_id;',
        target_table
    );

    -- nanda roads
    EXECUTE format(
        'UPDATE %I AS t
        SET num_streets = NULLIF(d.n_streets, ''-'')::INTEGER,
            prop_prim_sec_roads = NULLIF(d.prop_prim_sec_roads, ''-'')::FLOAT
        FROM nanda_roads AS d
        WHERE t.tract = d.tract_fips20;',
        target_table
    );

    -- nanda street connectivity
    EXECUTE format(
        'UPDATE %I AS t
        SET intersection_density = NULLIF(d.intdensity, ''-'')::FLOAT,
            street_network_density = NULLIF(d.strnetdensity, ''-'')::FLOAT,
            connected_node_ratio = NULLIF(d.connoderatio, ''-'')::FLOAT
        FROM nanda_street_connectivity AS d
        WHERE t.tract = d.tract_fips20;',
        target_table
    );

    -- nanda traffic
    EXECUTE format(
        'UPDATE %I AS t
        SET avg_traffic = NULLIF(d.mean_traffic, ''-'')::FLOAT,
            num_intersections = NULLIF(d.count_intersections, ''-'')::INTEGER
        FROM nanda_traffic AS d
        WHERE t.tract = d.tract_fips20;',
        target_table
    );
END;
$$ LANGUAGE plpgsql;


-- call join_regression_data function
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
        PERFORM join_regression_data(target_table);
    END LOOP;
END $$;


-- insert wac data separately
UPDATE divvy_trips_aggregates_start AS t
SET num_jobs = d.c000::INTEGER
FROM il_wac_2022 AS d
WHERE t.tract = d.census_tract;

UPDATE citi_trips_aggregates_start AS t
SET num_jobs = d.c000::INTEGER
FROM ny_wac_2022 AS d
WHERE t.tract = d.census_tract;

UPDATE metro_trips_aggregates_start AS t
SET num_jobs = d.c000::INTEGER
FROM ca_wac_2022 AS d
WHERE t.tract = d.census_tract;

UPDATE divvy_trips_aggregates_end AS t
SET num_jobs = d.c000::INTEGER
FROM il_wac_2022 AS d
WHERE t.tract = d.census_tract;

UPDATE citi_trips_aggregates_end AS t
SET num_jobs = d.c000::INTEGER
FROM ny_wac_2022 AS d
WHERE t.tract = d.census_tract;

UPDATE metro_trips_aggregates_end AS t
SET num_jobs = d.c000::INTEGER
FROM ca_wac_2022 AS d
WHERE t.tract = d.census_tract;


-- delete all census tracts that have fewer than 100 trips (likely noise)
-- for chicago and nyc
DO $$
DECLARE
    target_table TEXT;
BEGIN
    FOREACH target_table IN ARRAY ARRAY[
        'divvy_trips_aggregates_start',
        'divvy_trips_aggregates_end',
        'citi_trips_aggregates_start',
        'citi_trips_aggregates_end'
    ]
    LOOP
        EXECUTE format(
            'DELETE FROM %I
             WHERE (
                COALESCE(mi_flm_count, 0) +
                COALESCE(mi_fm_count, 0) +
                COALESCE(mi_lm_count, 0) +
                COALESCE(ms_count, 0) +
                COALESCE(none_count, 0)
             ) <= 100;',
            target_table
        );
    END LOOP;
END $$;

-- use 25 as a threshold for la
DO $$
DECLARE
    target_table TEXT;
BEGIN
    FOREACH target_table IN ARRAY ARRAY[
        'metro_trips_aggregates_start',
        'metro_trips_aggregates_end'
    ]
    LOOP
        EXECUTE format(
            'DELETE FROM %I
             WHERE (
                COALESCE(mi_flm_count, 0) +
                COALESCE(mi_fm_count, 0) +
                COALESCE(mi_lm_count, 0) +
                COALESCE(ms_count, 0) +
                COALESCE(none_count, 0)
             ) <= 25;',
            target_table
        );
    END LOOP;
END $$;

----- divvy
CREATE TABLE divvy_trip_aggregates_start AS
SELECT
    start_tract,
    SUM(CASE WHEN classification = 'MI-FLM' THEN 1 ELSE 0 END) AS mi_flm_count,
    SUM(CASE WHEN classification = 'MI_FM' THEN 1 ELSE 0 END) AS mi_fm_count,
    SUM(CASE WHEN classification = 'MI-LM' THEN 1 ELSE 0 END) AS mi_lm_count,
    SUM(CASE WHEN classification = 'MS' THEN 1 ELSE 0 END) AS ms_count,
    SUM(CASE WHEN classification = 'NONE' THEN 1 ELSE 0 END) AS none_count
FROM divvy_trips
GROUP BY start_tract;

CREATE TABLE divvy_trip_aggregates_end AS
SELECT
    end_tract,
    SUM(CASE WHEN classification = 'MI-FLM' THEN 1 ELSE 0 END) AS mi_flm_count,
    SUM(CASE WHEN classification = 'MI_FM' THEN 1 ELSE 0 END) AS mi_fm_count,
    SUM(CASE WHEN classification = 'MI-LM' THEN 1 ELSE 0 END) AS mi_lm_count,
    SUM(CASE WHEN classification = 'MS' THEN 1 ELSE 0 END) AS ms_count,
    SUM(CASE WHEN classification = 'NONE' THEN 1 ELSE 0 END) AS none_count
FROM divvy_trips
GROUP BY end_tract;


----- citi
CREATE TABLE citi_trip_aggregates_start AS
SELECT
    start_tract,
    SUM(CASE WHEN classification = 'MI-FLM' THEN 1 ELSE 0 END) AS mi_flm_count,
    SUM(CASE WHEN classification = 'MI_FM' THEN 1 ELSE 0 END) AS mi_fm_count,
    SUM(CASE WHEN classification = 'MI-LM' THEN 1 ELSE 0 END) AS mi_lm_count,
    SUM(CASE WHEN classification = 'MS' THEN 1 ELSE 0 END) AS ms_count,
    SUM(CASE WHEN classification = 'NONE' THEN 1 ELSE 0 END) AS none_count
FROM citi_trips
GROUP BY start_tract;

CREATE TABLE citi_trip_aggregates_end AS
SELECT
    end_tract,
    SUM(CASE WHEN classification = 'MI-FLM' THEN 1 ELSE 0 END) AS mi_flm_count,
    SUM(CASE WHEN classification = 'MI_FM' THEN 1 ELSE 0 END) AS mi_fm_count,
    SUM(CASE WHEN classification = 'MI-LM' THEN 1 ELSE 0 END) AS mi_lm_count,
    SUM(CASE WHEN classification = 'MS' THEN 1 ELSE 0 END) AS ms_count,
    SUM(CASE WHEN classification = 'NONE' THEN 1 ELSE 0 END) AS none_count
FROM citi_trips
GROUP BY end_tract;


----- metro
CREATE TABLE metro_trip_aggregates_start AS
SELECT
    start_tract,
    SUM(CASE WHEN classification = 'MI-FLM' THEN 1 ELSE 0 END) AS mi_flm_count,
    SUM(CASE WHEN classification = 'MI_FM' THEN 1 ELSE 0 END) AS mi_fm_count,
    SUM(CASE WHEN classification = 'MI-LM' THEN 1 ELSE 0 END) AS mi_lm_count,
    SUM(CASE WHEN classification = 'MS' THEN 1 ELSE 0 END) AS ms_count,
    SUM(CASE WHEN classification = 'NONE' THEN 1 ELSE 0 END) AS none_count
FROM metro_trips
GROUP BY start_tract;

CREATE TABLE metro_trip_aggregates_end AS
SELECT
    end_tract,
    SUM(CASE WHEN classification = 'MI-FLM' THEN 1 ELSE 0 END) AS mi_flm_count,
    SUM(CASE WHEN classification = 'MI_FM' THEN 1 ELSE 0 END) AS mi_fm_count,
    SUM(CASE WHEN classification = 'MI-LM' THEN 1 ELSE 0 END) AS mi_lm_count,
    SUM(CASE WHEN classification = 'MS' THEN 1 ELSE 0 END) AS ms_count,
    SUM(CASE WHEN classification = 'NONE' THEN 1 ELSE 0 END) AS none_count
FROM metro_trips
GROUP BY end_tract;
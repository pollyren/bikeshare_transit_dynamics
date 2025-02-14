
-- standardise geoid for joining, only keep state, county, tract
ALTER TABLE latch_2017 RENAME COLUMN geocode TO geo_id;

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
#!/bin/bash

set -e

if [ -f ../.env ]; then
    export $(grep -v '^#' ../.env | xargs)
fi

## create raw tables
psql -d $DB_NAME -c "
    CREATE TABLE IF NOT EXISTS latch_2017 (geocode TEXT, urban_group VARCHAR(10), est_vmiles TEXT);

    CREATE TABLE IF NOT EXISTS acs5y2023_socioeconomic (
        GEO_ID TEXT, DP02_0016E TEXT, DP02_0022E TEXT, DP02_0059E TEXT, DP02_0067E TEXT, DP02_0068E TEXT,
        DP02_0079E TEXT, DP02_0080E TEXT, DP02_0152E TEXT, DP02_0154E TEXT
    );

    CREATE TABLE IF NOT EXISTS acs5y2023_employment (
        GEO_ID TEXT, DP03_0018E TEXT, DP03_0019E TEXT, DP03_0020E TEXT, DP03_0021E TEXT,
        DP03_0022E TEXT, DP03_0025E TEXT, DP03_0062E TEXT, DP03_0009PE TEXT
    );

    CREATE TABLE IF NOT EXISTS acs5y2023_demographic (
        GEO_ID TEXT, DP05_0018E TEXT, DP05_0091E TEXT
    );

    CREATE TABLE IF NOT EXISTS acs5y2023_housing (
        GEO_ID TEXT, S2504_C01_027E TEXT
    );

    CREATE TABLE IF NOT EXISTS ca_wac_S000_JT00_2022 (geocode TEXT, C000 TEXT);
    CREATE TABLE IF NOT EXISTS il_wac_S000_JT00_2022 (geocode TEXT, C000 TEXT);
    CREATE TABLE IF NOT EXISTS ny_wac_S000_JT00_2022 (geocode TEXT, C000 TEXT);

    CREATE TABLE IF NOT EXISTS nanda_roads (
        TRACT_FIPS20 TEXT, N_STREETS TEXT, PROP_PRIM_SEC_ROADS TEXT
    );

    CREATE TABLE IF NOT EXISTS nanda_street_connectivity (
        TRACT_FIPS20 TEXT, INTDENSITY TEXT, STRNETDENSITY TEXT, CONNODERATIO TEXT
    );

    CREATE TABLE IF NOT EXISTS nanda_traffic (
        TRACT_FIPS20 TEXT, MEAN_TRAFFIC TEXT, COUNT_INTERSECTIONS TEXT
    );
"


## load regression data into raw tables
# load latch (local area transportation characteristics for households) data
cut -d',' -f1,3,10 ../data/variables/latch_2017.csv | \
psql -d $DB_NAME -c "\COPY latch_2017 FROM stdin WITH CSV HEADER NULL '';"


# load census acs data
# remove row 2 from all ACS data because commas throw off cut anyway
sed '2d' ../data/variables/acs5y2023-socioeconomic.csv | \
cut -d',' -f1,33,45,119,135,137,159,161,305,309 | \
psql -d $DB_NAME -c "\COPY acs5y2023_socioeconomic FROM stdin WITH CSV HEADER NULL '';"

sed '2d' ../data/variables/acs5y2023-employment.csv | \
cut -d',' -f1,37,39,41,43,45,51,125,293 | \
psql -d $DB_NAME -c "\COPY acs5y2023_employment FROM stdin WITH CSV HEADER NULL '';"

sed '2d' ../data/variables/acs5y2023-demographic.csv | \
cut -d',' -f1,37,183 | \
psql -d $DB_NAME -c "\COPY acs5y2023_demographic FROM stdin WITH CSV HEADER NULL '';"

sed '2d' ../data/variables/acs5y2023-housing.csv | \
cut -d',' -f1,55 | \
psql -d $DB_NAME -c "\COPY acs5y2023_housing FROM stdin WITH CSV HEADER NULL '';"


# load wac (workplace area characteristics) data
cut -d',' -f1,2 ../data/variables/ca_wac_S000_JT00_2022.csv | \
psql -d $DB_NAME -c "\COPY ca_wac_S000_JT00_2022 FROM stdin WITH CSV HEADER NULL '';"

cut -d',' -f1,2 ../data/variables/il_wac_S000_JT00_2022.csv | \
psql -d $DB_NAME -c "\COPY il_wac_S000_JT00_2022 FROM stdin WITH CSV HEADER NULL '';"

cut -d',' -f1,2 ../data/variables/ny_wac_S000_JT00_2022.csv | \
psql -d $DB_NAME -c "\COPY ny_wac_S000_JT00_2022 FROM stdin WITH CSV HEADER NULL '';"


# load nanda (national neighborhood data archive) data
cat ../data/variables/nanda-street_connectivity.tsv | \
tr -s '\t' ',' | \
cut -d',' -f1,9,10,11 | \
psql -d $DB_NAME -c "\COPY nanda_street_connectivity FROM stdin WITH CSV HEADER NULL '';"

cat ../data/variables/nanda-traffic.tsv | \
tr -s '\t' ',' | \
cut -d',' -f1,3,18 | \
psql -d $DB_NAME -c "\COPY nanda_traffic FROM stdin WITH CSV HEADER NULL '';"

cat ../data/variables/nanda-roads.tsv | \
tr -s '\t' ',' | \
cut -d',' -f1,2,9 | \
psql -d $DB_NAME -c "\COPY nanda_roads FROM stdin WITH CSV HEADER NULL '';"


# join regression data
psql -d $DB_NAME -f combine_regression_data.sql


# write aggregated files to data/final
mkdir -p ../data/final

psql -d $DB_NAME -c "COPY divvy_trips_aggregates_start TO '$(realpath ../data/final)/divvy_start.csv' WITH CSV HEADER;"
psql -d $DB_NAME -c "COPY divvy_trips_aggregates_end TO '$(realpath ../data/final)/divvy_end.csv' WITH CSV HEADER;"
psql -d $DB_NAME -c "COPY citi_trips_aggregates_start TO '$(realpath ../data/final)/citi_start.csv' WITH CSV HEADER;"
psql -d $DB_NAME -c "COPY citi_trips_aggregates_end TO '$(realpath ../data/final)/citi_end.csv' WITH CSV HEADER;"
psql -d $DB_NAME -c "COPY metro_trips_aggregates_start TO '$(realpath ../data/final)/metro_start.csv' WITH CSV HEADER;"
psql -d $DB_NAME -c "COPY metro_trips_aggregates_end TO '$(realpath ../data/final)/metro_end.csv' WITH CSV HEADER;"

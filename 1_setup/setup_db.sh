#!/bin/bash

DB_NAME="bikeshare_transit_dynamics"

brew services restart postgresql@14

if pg_isready -q && ! psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    createdb "$DB_NAME"
fi

psql -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS postgis;"
psql -d $DB_NAME -f create_schema.sql --set ON_ERROR_STOP=on

# load bikeshare data into raw tables
for file in ../data/bikeshare/chicago/*.csv; do
    cat $file | psql -d $DB_NAME -c "\COPY divvy_trips_raw FROM stdin WITH CSV HEADER;"
done

for file in ../data/bikeshare/nyc/*.csv; do
    cat $file | psql -d $DB_NAME -c "\COPY citi_trips_raw FROM stdin WITH CSV HEADER;"
done

for file in ../data/bikeshare/la/*.csv; do
    cat $file | psql -d $DB_NAME -c "\COPY metro_trips_raw FROM stdin WITH CSV HEADER;"
done

# load data into final tables
psql -d $DB_NAME -f populate_tables.sql --set ON_ERROR_STOP=on
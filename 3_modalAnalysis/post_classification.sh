#!/bin/bash

set -e

if [ -f ../.env ]; then
    export $(grep -v '^#' ../.env | xargs)
fi

# save results of categorisation to csv in data/classified
mkdir -p ../data/classified

psql -d $DB_NAME -c "COPY divvy_trips TO '$(realpath ../data/classified)/divvy_trips.csv' WITH CSV HEADER;"
psql -d $DB_NAME -c "COPY citi_trips TO '$(realpath ../data/classified)/citi_trips.csv' WITH CSV HEADER;"
psql -d $DB_NAME -c "COPY metro_trips TO '$(realpath ../data/classified)/metro_trips.csv' WITH CSV HEADER;"

# generate plots of classification results
python3 plot_classification.py

# cleanup intermediate tables
psql -d $DB_NAME -f drop_intermediate_tables.sql --set ON_ERROR_STOP=on
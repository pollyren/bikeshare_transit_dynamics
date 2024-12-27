import json
import psycopg2
import psycopg2.sql
from psycopg2.extras import execute_values
import os
import sys
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    'dbname': os.getenv('DB_NAME'),
    'host': os.getenv('DB_HOST'),
    'port': os.getenv('DB_PORT')
}

CITIES = {'chicago': 'divvy', 'la': 'metro', 'nyc': 'citi'}

os.chdir(os.path.abspath(os.path.join(os.path.dirname(__file__), '../data/bikeshare')))

if __name__ == '__main__':
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()

        for city, provider in CITIES.items():
            table_name = f'{provider}_stations'

            # metro bikeshare does not provide station capacity information
            if city == 'la':
                cursor.execute(psycopg2.sql.SQL('''
                    CREATE TABLE IF NOT EXISTS {table} (
                        station_id TEXT PRIMARY KEY,
                        name TEXT,
                        lat FLOAT,
                        lon FLOAT,
                        geom GEOMETRY(Point, 4326)
                    );
                ''').format(table=psycopg2.sql.Identifier(table_name)))
            else:
                cursor.execute(psycopg2.sql.SQL('''
                    CREATE TABLE IF NOT EXISTS {table} (
                        station_id TEXT PRIMARY KEY,
                        name TEXT,
                        capacity INT,
                        lat FLOAT,
                        lon FLOAT,
                        geom GEOMETRY(Point, 4326)
                    );
                ''').format(table=psycopg2.sql.Identifier(table_name)))
            conn.commit()

            station_file = f'{city}/station_information.json'

            with open(station_file, 'r') as f:
                data = json.load(f)

            stations = []
            for station in data['data']['stations']:
                if city == 'la':
                    station_id = station['station_id'].split('_')[-1]
                else:
                    try:
                        station_id = station['short_name']
                    except KeyError:
                        continue    # lightweight stations do not have a short_name, excluding it here
                name = station['name']
                lat = station['lat']
                lon = station['lon']
                geom = f'SRID=4326;POINT({lon} {lat})'

                if city == 'la':
                    stations.append((station_id, name, lat, lon, geom))
                else:
                    capacity = station['capacity']
                    stations.append((station_id, name, capacity, lat, lon, geom))

            if city == 'la':
                query = psycopg2.sql.SQL('''
                    INSERT INTO {table} (station_id, name, lat, lon, geom)
                    VALUES %s
                    ON CONFLICT (station_id) DO NOTHING;
                ''').format(table=psycopg2.sql.Identifier(table_name))
            else:
                query = psycopg2.sql.SQL('''
                    INSERT INTO {table} (station_id, name, capacity, lat, lon, geom)
                    VALUES %s
                    ON CONFLICT (station_id) DO NOTHING;
                ''').format(table=psycopg2.sql.Identifier(table_name))

            execute_values(cursor, query, stations)

            conn.commit()
            print(f'{city} data loaded successfully.')

    except Exception as e:
        print(f'error: {e}')
        sys.exit(1)

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
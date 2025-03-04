import psycopg2
import os
import sys
import pandas as pd
from io import StringIO
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    'dbname': os.getenv('DB_NAME'),
    'host': os.getenv('DB_HOST'),
    'port': os.getenv('DB_PORT')
}

YEAR = os.getenv('YEAR')

QUARTERS = ['q1', 'q2', 'q3', 'q4']

AGENCIES = {
    'cta': 'chicago',
    'mta': 'nyc',
    'metro': 'la'
}

os.chdir(os.path.abspath(os.path.join(os.path.dirname(__file__), '../data/gtfs')))

def generate_create_table_sql(agency, stop_only):
    queries = []

    for quarter in QUARTERS:
        queries.extend([
            f'''
            CREATE TABLE IF NOT EXISTS {agency}_{quarter}_stops (
                stop_id TEXT PRIMARY KEY,
                stop_name TEXT,
                stop_lat DOUBLE PRECISION,
                stop_lon DOUBLE PRECISION,
                geom GEOMETRY(Point, 4326) DEFAULT NULL
            );
            '''
        ])

        if not stop_only:
            queries.extend([
                f'''
                CREATE TABLE IF NOT EXISTS {agency}_{quarter}_routes (
                    route_id TEXT PRIMARY KEY,
                    route_short_name TEXT,
                    route_long_name TEXT,
                    route_type INTEGER
                );
                ''',
                f'''
                CREATE TABLE IF NOT EXISTS {agency}_{quarter}_trips (
                    trip_id TEXT PRIMARY KEY,
                    route_id TEXT REFERENCES {agency}_{quarter}_routes(route_id),
                    service_id TEXT
                );
                ''',
                f'''
                CREATE TABLE IF NOT EXISTS {agency}_{quarter}_stop_times (
                    id SERIAL PRIMARY KEY,
                    trip_id TEXT REFERENCES {agency}_{quarter}_trips(trip_id),
                    stop_id TEXT REFERENCES {agency}_{quarter}_stops(stop_id),
                    arrival_time TIME,
                    departure_time TIME,
                    stop_sequence INTEGER
                );
                ''',
                f'''
                CREATE TABLE IF NOT EXISTS {agency}_{quarter}_calendar (
                    service_id TEXT PRIMARY KEY,
                    monday BOOLEAN,
                    tuesday BOOLEAN,
                    wednesday BOOLEAN,
                    thursday BOOLEAN,
                    friday BOOLEAN,
                    saturday BOOLEAN,
                    sunday BOOLEAN,
                    start_date DATE,
                    end_date DATE
                );
                '''
            ])

    return queries

def create_tables(cursor, stop_only):
    for agency in AGENCIES:
        create_table_sqls = generate_create_table_sql(agency, stop_only)
        for sql in create_table_sqls:
            cursor.execute(sql)

        print(f'completed {agency}')

def dataframe_to_csv_buffer(df, columns):
    buffer = StringIO()
    df[columns].to_csv(buffer, index=False, header=False)  # Include only specified columns
    buffer.seek(0)
    return buffer

def validate_time_format(df):
    for col in ['arrival_time', 'departure_time']:
        df[col] = pd.to_datetime(df[col], format='%H:%M:%S', errors='coerce')

    df = df.dropna(subset=['arrival_time', 'departure_time']).reset_index(drop=True)
    return df

def load_gtfs_data(cursor, agency, quarter, stop_only):
    combined_data = {
        'stops': pd.DataFrame(),
    }

    column_mappings = {
        'stops': ['stop_id', 'stop_name', 'stop_lat', 'stop_lon'],
    }

    if not stop_only:
        combined_data.update({
            'routes': pd.DataFrame(),
            'trips': pd.DataFrame(),
            'stop_times': pd.DataFrame(),
            'calendar': pd.DataFrame()
        })

        column_mappings.update({
            'routes': ['route_id', 'route_short_name', 'route_long_name', 'route_type'],
            'trips': ['trip_id', 'route_id', 'service_id'],
            'stop_times': ['trip_id', 'stop_id', 'arrival_time', 'departure_time', 'stop_sequence'],
            'calendar': ['service_id', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
        })

    gtfs_path = AGENCIES[agency]

    for folder in os.listdir(gtfs_path):
        if quarter in folder:
            folder_path = os.path.join(gtfs_path, folder)
            print(f'processing {folder_path}...')

            stops = pd.read_csv(os.path.join(folder_path, 'stops.txt'))
            combined_data['stops'] = pd.concat([combined_data['stops'], stops])

            if not stop_only:
                routes = pd.read_csv(os.path.join(folder_path, 'routes.txt'))
                combined_data['routes'] = pd.concat([combined_data['routes'], routes])

                trips = pd.read_csv(os.path.join(folder_path, 'trips.txt'))
                combined_data['trips'] = pd.concat([combined_data['trips'], trips])

                stop_times = pd.read_csv(os.path.join(folder_path, 'stop_times.txt'))
                stop_times = validate_time_format(stop_times)
                combined_data['stop_times'] = pd.concat([combined_data['stop_times'], stop_times])

                if 'lirr' in folder or 'mnr' in folder: # mta rail missing calendars, assume weekday schedules
                    calendar_entries = []
                    service_ids_from_trips = set(trips['service_id'])
                    for service_id in service_ids_from_trips:
                        entry = {
                            'service_id': service_id,
                            'monday': 1,
                            'tuesday': 1,
                            'wednesday': 1,
                            'thursday': 1,
                            'friday': 1,
                            'saturday': 0,
                            'sunday': 0,
                            'start_date': f'{YEAR}0101',
                            'end_date': f'{YEAR}1231'
                        }
                        calendar_entries.append(entry)

                    calendar = pd.DataFrame(calendar_entries)
                    combined_data['calendar'] = pd.concat([combined_data['calendar'], calendar])

                else:
                    calendar = pd.read_csv(os.path.join(folder_path, 'calendar.txt'))
                    combined_data['calendar'] = pd.concat([combined_data['calendar'], calendar])

    for key, columns in column_mappings.items():
        combined_data[key] = combined_data[key].drop_duplicates(subset=[columns[0]]).reset_index(drop=True)

    for table, columns in column_mappings.items():
        buffer = dataframe_to_csv_buffer(combined_data[table], columns)

        if table == 'stops':
            sql = f'''
                COPY {agency}_{quarter}_stops (stop_id, stop_name, stop_lat, stop_lon)
                FROM STDIN WITH (FORMAT csv, DELIMITER ',', NULL '')
            '''
        else:
            sql = f'''
                COPY {agency}_{quarter}_{table} ({', '.join(columns)})
                FROM STDIN WITH (FORMAT csv, DELIMITER ',', NULL '')
            '''
        cursor.copy_expert(sql, buffer)
        print(f'loaded {table} for {quarter}')

def update_stops_geom(cursor, table):
    cursor.execute(f'''
        UPDATE {table}
        SET geom = ST_SetSRID(ST_MakePoint(stop_lon, stop_lat), 4326)
        WHERE geom IS NULL;
    ''')
    print(f'updated geom column for {table}')

if __name__ == '__main__':
    stop_only = "--stop-only" in sys.argv

    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()

        create_tables(cursor, stop_only)
        conn.commit()

        for agency in AGENCIES:
            for quarter in QUARTERS:
                load_gtfs_data(cursor, agency, quarter, stop_only)
        conn.commit()

        for agency in AGENCIES:
            for quarter in QUARTERS:
                update_stops_geom(cursor, f'{agency}_{quarter}_stops')
        conn.commit()

    except Exception as e:
        print(f'error: {e}')
        sys.exit(1)

    finally:
        if conn:
            cursor.close()
            conn.close()

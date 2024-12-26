import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os

DF_TYPES = {
    'ride_id': 'object',
    'rideable_type': 'object',
    # 'started_at': 'datetime64',
    # 'ended_at': 'datetime64',
    'start_station_name': 'object',
    'start_station_id': 'object',
    'end_station_name': 'object',
    'end_station_id': 'object',
    'start_lat': 'float64',
    'start_lng': 'float64',
    'end_lat': 'float64',
    'end_lng': 'float64',
    'member_casual': 'object'
}

DF_TYPES_LA = {
    'trip_id': 'object',
    'duration': 'int64',
    # 'start_time': 'datetime64',
    # 'end_time': 'datetime64',
    'start_station': 'object',
    'start_lat': 'float64',
    'start_lon': 'float64',
    'end_station': 'object',
    'end_lat': 'float64',
    'end_lon': 'float64',
    'bike_id': 'object',
    'plan_duration': 'object',
    'trip_route_category': 'object',
    'passholder_type': 'object',
    'bike_type': 'object'
}

COLOURS = {
    'Divvy': '#477998',
    'Citi': '#841C26',
    'Metro': '#87AC5D'
}

TIMES = {
    'Early morning (12 AM - 4 AM)': (0, 4),
    'Morning (4 AM - 8 AM)': (4, 8),
    'Late morning (8 AM - 12PM)': (8, 12),
    'Afternoon (12 PM - 4 PM)': (12, 16),
    'Evening (4 PM - 8 PM)': (16, 20),
    'Night (8 PM - 12 AM)': (20, 24),
}


def read_and_filter_data():
    cities = {'chicago': [], 'nyc': [], 'la': []}
    cities_df = {}
    for city in cities:
        path = f'../data/bikeshare/{city}'
        for file in os.listdir(path):
            if file.endswith('.csv'):
                cities[city].append(pd.read_csv(
                    os.path.join(path, file), 
                    dtype=DF_TYPES_LA if city == 'la' else DF_TYPES,
                    parse_dates=['start_time', 'end_time'] if city == 'la' else ['started_at', 'ended_at']
                ))
        cities_df[city] = pd.concat(cities[city])

    for city, df in cities_df.items():
        print(df.info())

    divvy_raw = pd.DataFrame(
        cities_df['chicago'][[
            'ride_id', 'rideable_type', 'started_at', 'ended_at', 'start_station_id', 
            'end_station_id', 'start_lat', 'start_lng', 'end_lat', 'end_lng', 'member_casual'
        ]])

    citi_raw = pd.DataFrame(
        cities_df['nyc'][[
            'ride_id', 'rideable_type', 'started_at', 'ended_at', 'start_station_id', 
            'end_station_id', 'start_lat', 'start_lng', 'end_lat', 'end_lng', 'member_casual'
        ]])

    metro_raw = pd.DataFrame(
        cities_df['la'][[
            'trip_id', 'bike_type', 'start_time', 'end_time', 'start_station', 
            'end_station', 'start_lat', 'start_lon', 'end_lat', 'end_lon', 'passholder_type'
        ]].rename(columns={
            'trip_id': 'ride_id',
            'bike_type': 'rideable_type',
            'start_time': 'started_at',
            'end_time': 'ended_at', 
            'start_station': 'start_station_id',
            'end_station': 'end_station_id',
            'start_lon': 'start_lng',
            'end_lon': 'end_lng',
            'passholder_type': 'member_casual'
        }))
    
    def filter_and_clean_data(df):
        # only consider 2023 data
        df = df[df['started_at'].dt.year == 2023].copy()

        # compute trip duration
        df['trip_duration_min'] = (df['ended_at'] - df['started_at']).dt.total_seconds() / 60

        # remove trips that don't start or end at a dock
        df.dropna(subset=['start_station_id', 'end_station_id'], inplace=True)

        # remove trips that start and end at the same station
        df = df[df['start_station_id'] != df['end_station_id']]

        # remove trips that are shorter than 1 min or longer than 90 min
        return df[(df['trip_duration_min'] > 1) & (df['trip_duration_min'] <= 90)].copy()
    
    divvy = filter_and_clean_data(divvy_raw)
    citi = filter_and_clean_data(citi_raw)
    metro = filter_and_clean_data(metro_raw)

    return divvy, citi, metro


def plot_monthly_usage(info):
    def get_monthly_usage(df):
        df['year_month'] = df['started_at'].dt.to_period('M')
        monthly_trips = df.groupby('year_month').size().reset_index(name='trip_count')
        return monthly_trips

    plt.figure(figsize=(9, 6))

    for provider, df in info.items():
        df_monthly = get_monthly_usage(df)

        plt.plot(
            df_monthly['year_month'].astype(str), 
            df_monthly['trip_count'], 
            label=provider, 
            marker='o', 
            linestyle='-', 
            color=COLOURS[provider]
        )

    plt.title('Monthly bikeshare trips (2023)', fontsize=16)
    plt.xlabel('Month', fontsize=12)
    plt.ylabel('Number of trips', fontsize=12)
    plt.xticks(rotation=45)
    plt.legend()
    plt.grid(True)
    plt.tight_layout()

    plt.savefig('plots/monthly_trips.png')


def plot_trip_duration(info):
    def classify_time(hour):
        for period, (start, end) in TIMES.items():
            if start <= hour < end:
                return period
        return None

    avg_durations = []
    trip_counts = []
    for df in info.values():
        df['time_of_day'] = df['started_at'].dt.hour.map(classify_time)

        avg_duration = df.groupby('time_of_day')['trip_duration_min'].mean()
        count = df.groupby('time_of_day').size()

        avg_durations.append(avg_duration)
        trip_counts.append(count)

    avg_duration_df = pd.DataFrame(avg_durations, index=list(info.keys())).T
    avg_duration_df.index = list(TIMES.keys())

    trip_count_df = pd.DataFrame(trip_counts, index=list(info.keys())).T
    trip_count_df.index = list(TIMES.keys())

    wrapped_labels = [
        label.split('(', 1)[0] + '\n(' + label.split('(', 1)[1] if '(' in label else label
        for label in avg_duration_df.index
    ]

    x = np.arange(len(avg_duration_df.index))
    width = 0.2

    plt.figure(figsize=(9, 6))

    for i, provider in enumerate(info.keys()):
        plt.bar(
            x + i * width,
            avg_duration_df[provider],
            width=width,
            label=provider,
            color=COLOURS[provider]
        )

    plt.title('Average trip duration by time of day', fontsize=16)
    plt.xlabel('Time of Day', fontsize=12)
    plt.ylabel('Average Trip Duration (minutes)', fontsize=12)
    plt.xticks(x + width, wrapped_labels, rotation=0)
    plt.legend()
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()

    plt.savefig('plots/trip_duration.png')


def plot_trip_counts_heatmap(info):
    trip_counts = []
    for df in info.values():
        count = df.groupby('time_of_day').size()
        trip_counts.append(count)

    trip_count_df = pd.DataFrame(trip_counts, index=list(info.keys())).T
    trip_count_df.index = list(TIMES.keys())

    trip_count_norm = trip_count_df.div(trip_count_df.sum(axis=0), axis=1) * 100

    plt.figure(figsize=(8, 6))
    sns.heatmap(
        trip_count_norm, 
        annot=True, 
        fmt=".1f",
        cmap="Blues", 
        cbar_kws={'label': 'Percentage (%)'}
    )
    plt.title('Relative trip counts by time of day', fontsize=16)
    plt.xlabel('Bikeshare system', fontsize=12)
    plt.ylabel('Time of day', fontsize=12)
    plt.tight_layout()

    plt.savefig('plots/trip_counts_heatmap.png')


def plot_trip_counts_hourly_heatmap(info):
    trip_counts = []
    for df in info.values():
        count = df.groupby(df['started_at'].dt.hour).size()
        trip_counts.append(count)

    trip_count_df = pd.DataFrame(trip_counts, index=list(info.keys())).T
    trip_count_df.index.name = "Hour"

    trip_count_norm = trip_count_df.div(trip_count_df.sum(axis=0), axis=1) * 100

    plt.figure(figsize=(8, 8))
    sns.heatmap(
        trip_count_norm, 
        annot=True, 
        fmt=".1f", 
        cmap="Blues", 
        cbar_kws={'label': 'Percentage (%)'}
    )
    plt.title('Relative trip counts by hour', fontsize=16)
    plt.xlabel('Bikeshare system', fontsize=12)
    plt.ylabel('Hour (24-hour format)', fontsize=12)
    plt.tight_layout()

    plt.savefig('plots/trip_counts_hourly_heatmap.png')


if __name__ == '__main__':
    divvy, citi, metro = read_and_filter_data()
    info = {
        'Divvy': divvy,
        'Citi': citi,
        'Metro': metro
    }

    for provider, df in info.items():
        print(provider)
        print(df.info())

    plot_monthly_usage(info)
    plot_trip_duration(info)
    plot_trip_counts_heatmap(info)
    plot_trip_counts_hourly_heatmap(info)
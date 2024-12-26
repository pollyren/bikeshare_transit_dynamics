import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sqlalchemy import create_engine

DF_TYPES = {
    'ride_id': 'object',
    'rideable_type': 'object',
    'started_at': 'datetime64[ns]',
    'ended_at': 'datetime64[ns]',
    'start_station_id': 'object',
    'end_station_id': 'object',
    'start_lat': 'float64',
    'start_lng': 'float64',
    'end_lat': 'float64',
    'end_lng': 'float64',
    'member_casual': 'object'
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
    try:
        engine = create_engine('postgresql://localhost:5432/bikeshare_transit_dynamics')
        
        queries = {
            'Divvy': 'SELECT * FROM divvy_trips;',
            'Citi': 'SELECT * FROM citi_trips;',
            'Metro': 'SELECT * FROM metro_trips;'
        }
        
        info = {}

        for provider, query in queries.items():
            info[provider] = pd.read_sql(query, engine)
            
            for col, dtype in DF_TYPES.items():
                if col in info[provider].columns:
                    info[provider][col] = info[provider][col].astype(dtype)

    except Exception as e:
        print(f'error: {e}')

    for provider, df in info.items():
        print(provider)
        print(df.info())

    return info


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
        fmt='.1f',
        cmap='Blues', 
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
    trip_count_df.index.name = 'Hour'

    trip_count_norm = trip_count_df.div(trip_count_df.sum(axis=0), axis=1) * 100

    plt.figure(figsize=(8, 8))
    sns.heatmap(
        trip_count_norm, 
        annot=True, 
        fmt='.1f', 
        cmap='Blues', 
        cbar_kws={'label': 'Percentage (%)'}
    )
    plt.title('Relative trip counts by hour', fontsize=16)
    plt.xlabel('Bikeshare system', fontsize=12)
    plt.ylabel('Hour (24-hour format)', fontsize=12)
    plt.tight_layout()

    plt.savefig('plots/trip_counts_hourly_heatmap.png')


if __name__ == '__main__':
    info = read_and_filter_data()

    for provider, df in info.items():
        df['trip_duration_min'] = (df['ended_at'] - df['started_at']).dt.total_seconds() / 60

        print(provider)
        print(df.info())

    plot_monthly_usage(info)
    plot_trip_duration(info)
    plot_trip_counts_heatmap(info)
    plot_trip_counts_hourly_heatmap(info)
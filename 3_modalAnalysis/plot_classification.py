import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap, Normalize
from matplotlib.cm import ScalarMappable
import folium
from folium.plugins import HeatMap
from selenium import webdriver
from PIL import Image
import time
import os

MODAL_COLOURS = {
    'MI-FLM': '#0B5563', 
    'MI-FM': '#118A8F', 
    'MI-LM': '#17BEBB', 
    'MS': '#E4572E', 
    'none': 'lightgrey'
} 

CITY_COLOURS = {
    'Chicago': '#477998', 
    'NYC': '#841C26', 
    'LA': '#87AC5D'
}

CITIES = {
    'Chicago': 'Chicago',
    'NYC': 'New York City',
    'LA': 'Los Angeles'
}

CITY_TO_PROVIDER_TITLE = {
    'Chicago': 'Divvy + CTA', 
    'NYC': 'Citi Bike + MTA', 
    'LA': 'Metro Bikeshare + Metro'
}

MONTHS = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
]

CLASSIFICATIONS = {
    'mi': ['MI-FLM', 'MI-FM', 'MI-LM'],
    'ms': ['MS'],
    'none': ['none']
}

CURRENT_DIR = os.getcwd()
CLASSIFIED_DIR = '../data/classified'

COLUMNS = [
    'member_casual', 
    'rideable_type', 
    'start_station_id',
    'started_at', 
    'start_lat', 
    'start_lng', 
    'classification'
]

DTYPES = {
    'member_casual': 'object',
    'rideable_type': 'object',
    'start_station_id': 'object',
    'start_lat': 'float64',
    'start_lng': 'float64',
    'classification': 'object'
}

with open('../jawg_apikey.txt', 'r') as f:
    JAWG_TOKEN = f.readline().strip()
    
JAWG_TILES = f'https://tile.jawg.io/jawg-light/{{z}}/{{x}}/{{y}}.png?access-token={JAWG_TOKEN}'


def plot_hourly_classification(info):
    print('plotting hourly classification...')

    fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(18, 6))
    fig.suptitle('Hourly usage and classification', fontsize=18)

    for ax, city in zip(axes, CITIES):
        df = info[city]
        title = f'{CITIES[city]} ({CITY_TO_PROVIDER_TITLE[city]})'

        df['hour'] = pd.to_datetime(df['started_at'], errors='coerce').dt.hour
        df = df.dropna(subset=['hour'])

        grouped = df.groupby(['hour', 'classification']).size().unstack(fill_value=0)

        hours = grouped.index
        classifications = grouped.columns

        bottom = pd.Series(0, index=hours)

        for classification in classifications:
            ax.bar(
                hours,
                grouped[classification],
                bottom=bottom,
                label=classification,
                color=MODAL_COLOURS[classification],
                edgecolor='white'
            )
            bottom += grouped[classification]

        ax.set_title(title, fontsize=14)
        ax.set_xlabel('Hour (24-hour format)', fontsize=12)
        ax.set_xticks(range(0, 24))
        ax.grid(axis='y', linestyle='--', alpha=0.7)
        ax.set_ylabel('Number of trips', fontsize=12)

    handles, labels = axes[0].get_legend_handles_labels()

    fig.legend(
        handles, labels,
        title='Classification',
        loc='lower center',
        bbox_to_anchor=(0.5, -0.1),
        ncol=len(MODAL_COLOURS),
        fontsize=10
    )

    plt.draw()
    plt.tight_layout(rect=[0, 0, 1, 1])
    plt.savefig('output/hourly_classification.png', bbox_inches='tight')


def plot_monthly_classification(info):
    print('plotting monthly classification...')
    
    fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(18, 6))
    fig.suptitle('Monthly usage and classification', fontsize=18)

    for ax, city in zip(axes, CITIES):
        df = info[city]
        title = f'{CITIES[city]} ({CITY_TO_PROVIDER_TITLE[city]})'

        df['month'] = pd.to_datetime(df['started_at'], errors='coerce').dt.month
        df = df.dropna(subset=['month'])

        grouped = df.groupby(['month', 'classification']).size().unstack(fill_value=0)
        grouped.index = pd.to_datetime(grouped.index, format='%m').month_name()
        grouped = grouped.loc[MONTHS]

        months = grouped.index
        classifications = grouped.columns

        bottom = pd.Series(0, index=months)

        for classification in classifications:
            ax.bar(
                months,
                grouped[classification],
                bottom=bottom,
                label=classification,
                color=MODAL_COLOURS[classification],
                edgecolor='white'
            )
            bottom += grouped[classification]

        ax.set_title(title, fontsize=14)
        ax.set_xlabel('Month', fontsize=12)
        ax.set_xticks(range(12))
        ax.set_xticklabels(months, rotation=45, ha='right')
        ax.grid(axis='y', linestyle='--', alpha=0.7)
        ax.set_ylabel('Number of trips', fontsize=12)

    handles, labels = axes[0].get_legend_handles_labels()

    fig.legend(
        handles, labels,
        title='Classification',
        loc='lower center',
        bbox_to_anchor=(0.5, -0.1),
        ncol=len(MODAL_COLOURS),
        fontsize=10
    )

    plt.draw()
    plt.tight_layout(rect=[0, 0, 1, 1])
    plt.savefig('output/monthly_classification.png')


def _type_to_str(t):
    if t == 'mi': 
        return 'modal integration'
    if t == 'ms': 
        return 'modal substitution'
    return 'neither'


def plot_hourly_percentage(info, classification):
    print(f'plotting hourly {classification} percentages...')

    all_data = pd.DataFrame()

    for city in CITIES:
        df = info[city]

        df['hour'] = pd.to_datetime(df['started_at'], errors='coerce').dt.hour
        df = df.dropna(subset=['hour'])

        classifications = CLASSIFICATIONS[classification]
        filtered_df = df[df['classification'].isin(classifications)]

        total_trips_per_hour = df.groupby('hour').size()
        classified_trips_per_hour = filtered_df.groupby(['hour']).size()

        percentages = (classified_trips_per_hour / total_trips_per_hour) * 100
        percentages = percentages.fillna(0)
        percentages = percentages.reset_index(name='percentage')
        percentages['city'] = city

        all_data = pd.concat([all_data, percentages], ignore_index=True)

    plt.figure(figsize=(8,6))

    for city in CITIES:
        city_data = all_data[all_data['city'] == city]
        plt.plot(
            city_data['hour'],
            city_data['percentage'],
            label=city,
            color=CITY_COLOURS[city]
        )

    plt.xlabel('Hour (24-hour format)', fontsize=12)
    plt.ylabel(f'Percentage of {classification.upper()} trips (%)', fontsize=12)
    plt.title(f'Percentage of {_type_to_str(classification)} trips by hour', fontsize=14)
    plt.legend(title='City', fontsize=10, loc='upper right')
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.ylim(-1, plt.ylim()[1] * 1.1)

    plt.tight_layout()
    plt.savefig(f'output/{classification}_percentage.png')


def plot_heatmaps_individual(info, classification):
    print(f'plotting {classification} heatmaps...')

    for city, df in info.items():
        df = df.dropna(subset=['start_lat', 'start_lng'])
        
        classifications = CLASSIFICATIONS[classification]
        
        total_trips = df.groupby('start_station_id').size()
        filtered_trips = df[df['classification'].isin(classifications)].groupby('start_station_id').size()
        percentages = (filtered_trips / total_trips * 100).fillna(0).reset_index(name=f'{classification}_percentage')
        
        station_coords = df.groupby('start_station_id')[['start_lat', 'start_lng']].mean().reset_index()
        percentages = percentages.merge(station_coords, on='start_station_id', how='left').dropna()
        
        heat_data = percentages[['start_lat', 'start_lng', f'{classification}_percentage']].values.tolist()
        
        map_center = [df['start_lat'].mean(), df['start_lng'].mean()]

        m = folium.Map(
            location=map_center, 
            zoom_start=11,
            tiles=JAWG_TILES,
            attr='<a href="https://jawg.io" title="Tiles Courtesy of Jawg Maps" ' + 
                 'target="_blank">&copy; <b>Jawg</b>Maps</a> &copy; <a href=' + 
                 '"https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        )
        
        HeatMap(
            data=heat_data, 
            radius=5 if city != 'NYC' else 4,
            blur=3,
        ).add_to(m)

        map_path = os.path.join(
            CURRENT_DIR, 
            f'output/{city.lower()}_{classification}_percentage_heatmap.html'
        )
        m.save(map_path)

        options = webdriver.ChromeOptions()
        options.add_argument('--headless')
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')
        
        driver = webdriver.Chrome(options=options)
        driver.set_window_size(650, 800)
        
        driver.get(f'file://{map_path}')
        time.sleep(2)
        
        driver.save_screenshot(map_path[:-5] + '.png')
        driver.quit()

        print(f'\tdone with {city}')


def combine_heatmaps(classification):
    print(f'combining {classification} heatmaps...')

    colors = [(0, 'blue'), (0.33, 'lime'), (0.7, 'yellow'), (1.0, 'red')]
    cmap = LinearSegmentedColormap.from_list('folium_like', colors)

    fig, axes = plt.subplots(1, 3, figsize=(18, 6))
    fig.suptitle(f'Relative {_type_to_str(classification)} percentage', fontsize=18)

    for ax, city in zip(axes, CITIES):
        image_path = f'output/{city.lower()}_{classification}_percentage_heatmap.png'
        img = Image.open(image_path)
        
        ax.imshow(img)
        ax.axis('off')
        ax.set_title(f'{CITIES[city]} ({CITY_TO_PROVIDER_TITLE[city]})', fontsize=14)

    cbar_ax = fig.add_axes([0.92, 0.15, 0.02, 0.7])
    norm = Normalize(vmin=0, vmax=100)
    sm = ScalarMappable(norm=norm, cmap=cmap)

    cbar = plt.colorbar(sm, cax=cbar_ax)
    cbar.set_ticks([0, 100])
    cbar.set_ticklabels(['Low', 'High'])
    cbar.outline.set_linewidth(0.6)

    plt.tight_layout(rect=[0, 0, 0.918, 0.96])
    plt.savefig(f'output/{classification}_map.png', bbox_inches='tight')


if __name__ == '__main__':
    info = {
        'Chicago': pd.read_csv(
            f'{CLASSIFIED_DIR}/divvy_trips.csv', 
            dtype=DTYPES, 
            usecols=COLUMNS, 
            parse_dates=['started_at']
        ),
        'NYC': pd.read_csv(
            f'{CLASSIFIED_DIR}/citi_trips.csv', 
            dtype=DTYPES, 
            usecols=COLUMNS, 
            parse_dates=['started_at']
        ),
        'LA': pd.read_csv(
            f'{CLASSIFIED_DIR}/metro_trips.csv', 
            dtype=DTYPES, 
            usecols=COLUMNS, 
            parse_dates=['started_at']
        )
    }

    plot_hourly_classification(info)
    plot_monthly_classification(info)
    
    for classification in CLASSIFICATIONS:
        plot_hourly_percentage(info, classification)
        plot_heatmaps_individual(info, classification)
        combine_heatmaps(classification)
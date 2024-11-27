#!/bin/bash

bs_dir="../data/bikeshare"
mkdir -p "$bs_dir/chicago" "$bs_dir/la" "$bs_dir/nyc"

download_metro() {
    metro_urls=(
        "https://bikeshare.metro.net/wp-content/uploads/2023/04/metro-trips-2023-q1.zip"
        "https://bikeshare.metro.net/wp-content/uploads/2023/07/metro-trips-2023-q2.zip"
        "https://bikeshare.metro.net/wp-content/uploads/2023/10/metro-trips-2023-q3.zip"
        "https://bikeshare.metro.net/wp-content/uploads/2024/01/metro-trips-2023-q4.zip"
    )

    for url in "${metro_urls[@]}"; do
        wget -P "$bs_dir/la" "$url"
        echo "downloaded $url"
    done
}

download_divvy() {
    prefix="https://divvy-tripdata.s3.amazonaws.com/"
    suffix="-divvy-tripdata.zip"

    for month in $(seq -w 1 12); do
        url="${prefix}2023${month}${suffix}"
        wget -P "$bs_dir/chicago" "$url"
        echo "downloaded $url"
    done
}

download_citibike() {
    url="https://s3.amazonaws.com/tripdata/2023-citibike-tripdata.zip"
    wget -P "$bs_dir/nyc" "$url"
    echo "downloaded $url"

    for zip_file in "$bs_dir/nyc"/*.zip; do
        unzip -o "$zip_file" -d "$bs_dir/nyc"

        folder=$(basename "$zip_file" .zip)
    
        mv "$bs_dir/nyc/$folder"/* "$bs_dir/nyc"
        
        rmdir "$bs_dir/nyc/$folder"
        rm "$zip_file"
    done
}

download_station_info() {
    declare -A station_info=(
        ["chicago"]="https://gbfs.lyft.com/gbfs/1.1/chi/en/station_information.json"
        ["nyc"]="https://gbfs.citibikenyc.com/gbfs/en/station_information.json"
        ["la"]="https://gbfs.bcycle.com/bcycle_lametro/station_information.json"
    )

    for city in "${!station_info[@]}"; do
        url="${station_info[$city]}"
        dir="$bs_dir/$city"
        wget -P "$dir" "$url"
        echo "downloaded station information for $city"
    done
}

download_divvy
download_metro
download_citibike
download_station_info

for zip_file in $bs_dir/*/*.zip; do
    unzip -o "$zip_file" -d "$(dirname "$zip_file")"
    rm "$zip_file"
done

echo "bikeshare download complete."
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

    divvy_base_url="https://divvy-tripdata.s3.amazonaws.com/"
    citibike_base_url="https://s3.amazonaws.com/tripdata/"

    for url in "${metro_urls[@]}"; do
        wget -P "$bs_dir/la" "$url"
    done
}

download_divvy_citibike() {
    local divvy="$1"
    
    if [ "$divvy" = true ]; then
        dir="$bs_dir/chicago"
        prefix="https://divvy-tripdata.s3.amazonaws.com/"
        suffix="-divvy-tripdata.zip"
    else
        dir="$bs_dir/nyc"
        prefix="https://s3.amazonaws.com/tripdata/JC-"
        suffix="-citibike-tripdata.csv.zip"
    fi

    for month in $(seq -w 1 12); do
        url="${prefix}2023${month}${suffix}"
        wget -P "$dir" "$url"
        echo "downloaded $url"
    done
}

download_bikeshare() {
    local bss="$1"
    
    case "$bss" in
        "divvy")
            download_divvy_citibike true;;
        "citi")
            download_divvy_citibike false;;
        "metro")
            download_metro;;
        *)
            echo "invalid option";;
    esac
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

download_bikeshare "divvy"
download_bikeshare "metro"
download_bikeshare "citi"
download_station_info

for zip_file in $bs_dir/*/*.zip; do
    unzip -o "$zip_file" -d "$(dirname "$zip_file")"
    rm "$zip_file"
done

echo "bikeshare download complete."
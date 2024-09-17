#!/bin/bash

shp_dir="../data/shapefiles/"
mkdir -p "$shp_dir/chicago" "$shp_dir/la" "$shp_dir/nyc"

download_shp() {
    base_url="https://www2.census.gov/geo/tiger/TIGER2023/TRACT"
    
    for id in "06" "17" "36"; do
        url="${base_url}/tl_2023_${id}_tract.zip"

        case $id in
            06) city="la";;
            17) city="chicago";;
            36) city="nyc";;
        esac
        
        wget -P "$shp_dir/$city" "$url"
        unzip -q "$shp_dir/$city/tl_2023_${id}_tract.zip" -d "$shp_dir/$city/"
        rm "$shp_dir/$city/tl_2023_${id}_tract.zip"

        echo "downloaded for $city from $url"
    done
}

download_shp
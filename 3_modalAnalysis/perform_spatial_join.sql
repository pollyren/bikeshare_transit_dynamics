----- divvy
ALTER TABLE divvy_trips ADD COLUMN IF NOT EXISTS start_tract TEXT;
ALTER TABLE divvy_trips ADD COLUMN IF NOT EXISTS end_tract TEXT;
CREATE INDEX idx_divvy_trips_start_geom ON divvy_trips USING GIST(start_geom);
CREATE INDEX idx_divvy_trips_end_geom ON divvy_trips USING GIST(end_geom);

-- spatial join for start_geom
UPDATE divvy_trips
SET start_tract = census_tracts.geoid
FROM census_tracts
WHERE ST_Intersects(divvy_trips.start_geom, census_tracts.geom);

-- spatial join for end_geom
UPDATE divvy_trips
SET end_tract = census_tracts.geoid
FROM census_tracts
WHERE ST_Intersects(divvy_trips.end_geom, census_tracts.geom);


----- citi
ALTER TABLE citi_trips ADD COLUMN IF NOT EXISTS start_tract TEXT;
ALTER TABLE citi_trips ADD COLUMN IF NOT EXISTS end_tract TEXT;
CREATE INDEX idx_citi_trips_start_geom ON citi_trips USING GIST(start_geom);
CREATE INDEX idx_citi_trips_end_geom ON citi_trips USING GIST(end_geom);

-- spatial join for start_geom
UPDATE citi_trips
SET start_tract = census_tracts.geoid
FROM census_tracts
WHERE ST_Intersects(citi_trips.start_geom, census_tracts.geom);

-- spatial join for end_geom
UPDATE citi_trips
SET end_tract = census_tracts.geoid
FROM census_tracts
WHERE ST_Intersects(citi_trips.end_geom, census_tracts.geom);


----- metro
ALTER TABLE metro_trips ADD COLUMN IF NOT EXISTS start_tract TEXT;
ALTER TABLE metro_trips ADD COLUMN IF NOT EXISTS end_tract TEXT;
CREATE INDEX idx_metro_trips_start_geom ON metro_trips USING GIST(start_geom);
CREATE INDEX idx_metro_trips_end_geom ON metro_trips USING GIST(end_geom);

-- spatial join for start_geom
UPDATE metro_trips
SET start_tract = census_tracts.geoid
FROM census_tracts
WHERE ST_Intersects(metro_trips.start_geom, census_tracts.geom);

-- spatial join for end_geom
UPDATE metro_trips
SET end_tract = census_tracts.geoid
FROM census_tracts
WHERE ST_Intersects(metro_trips.end_geom, census_tracts.geom);


----- remove rows that are outside any valid census tracts
DELETE FROM divvy_trips WHERE start_tract IS NULL OR end_tract IS NULL;
DELETE FROM citi_trips WHERE start_tract IS NULL OR end_tract IS NULL;
DELETE FROM metro_trips WHERE start_tract IS NULL OR end_tract IS NULL;
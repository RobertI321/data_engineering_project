CREATE DATABASE IF NOT EXISTS bronze;

CREATE TABLE IF NOT EXISTS bronze.bronze_crime_raw (
    crime_id String,
    month String,
    reported_by String,
    falls_within String,
    longitude Float64,
    latitude Float64,
    location String,
    lsoa_code String,
    lsoa_name String,
    crime_type String,
    last_outcome_category String,
    context Float64,
    data_month String,
)
ENGINE = MergeTree()
PARTITION BY data_month
ORDER BY crime_id;

CREATE TABLE IF NOT EXISTS bronze.bronze_stopsearch_raw (
    type String,
    date String,
    part_of_a_policing_operation String,
    policing_operation Float64,
    latitude Float64,
    longitude Float64,
    gender String,
    age_range String,
    self_defined_ethnicity String,
    officer_defined_ethnicity String,
    legislation String,
    object_of_search String,
    outcome String,
    outcome_linked_to_object_of_search String,
    removal_of_more_than_just_outer_clothing String,
    data_month String,
)
ENGINE = MergeTree()
PARTITION BY data_month
ORDER BY date;

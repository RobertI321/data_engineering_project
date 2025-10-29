WITH crime AS (
    SELECT DISTINCT
        crime_id,
        month,
        reported_by,
        lsoa_code,
        lsoa_name,
        location,
        toFloat64(latitude) AS latitude,
        toFloat64(longitude) AS longitude,
        crime_type,
        last_outcome_category,
        data_month
    FROM {{ source('bronze','bronze_crime_raw') }}
    WHERE crime_id IS NOT NULL
)
SELECT
    crime_id AS CrimeID,
    parseDateTimeBestEffortOrNull(month) AS ReportedDate,
    reported_by AS PoliceForce,
    lsoa_code AS LSOACode,
    lsoa_name AS LSOAName,
    location AS LocationDescription,
    latitude AS Latitude,
    longitude AS Longitude,
    crime_type AS CrimeType,
    last_outcome_category AS OutcomeType,
    data_month AS DataMonth
FROM crime

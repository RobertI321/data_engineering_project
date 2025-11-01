WITH loc AS (
    SELECT DISTINCT
        LSOACode,
        LSOAName,
        LocationDescription,
        Latitude,
        Longitude
    FROM {{ ref('crime_clean') }}
)
SELECT
    row_number() OVER (ORDER BY LSOACode, LSOAName, LocationDescription) AS LocationKey,
    LSOACode,
    LSOAName,
    LocationDescription,
    Latitude,
    Longitude
FROM loc

WITH loc AS (
    SELECT DISTINCT
        LSOACode,
        LSOAName,
        LocationDescription,
        Latitude,
        Longitude
    FROM {{ ref('crime_clean') }}
    WHERE LSOACode IS NOT NULL
)
SELECT
    row_number() OVER (ORDER BY LSOACode, LSOAName, LocationDescription) AS LocationKey,
    LSOACode,
    LSOAName,
    LocationDescription,
    Latitude,
    Longitude
FROM loc

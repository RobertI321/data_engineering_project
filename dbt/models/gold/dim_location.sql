WITH combined AS (
    SELECT
        LSOACode,
        LSOAName,
        LocationDescription,
        round(Latitude, 3) AS Latitude,
        round(Longitude, 3) AS Longitude
    FROM {{ ref('crime_clean') }}
    UNION ALL
    SELECT
        NULL AS LSOACode,
        NULL AS LSOAName,
        NULL AS LocationDescription,
        round(Latitude, 3) AS Latitude,
        round(Longitude, 3) AS Longitude
    FROM {{ ref('stopsearch_clean') }}
),
loc AS (
    SELECT
        Latitude,
        Longitude,
        any(LSOACode)            AS LSOACode,
        any(LSOAName)            AS LSOAName,
        any(LocationDescription) AS LocationDescription
    FROM combined
    GROUP BY
        Latitude,
        Longitude
)
SELECT
    row_number() OVER (ORDER BY Latitude, Longitude) AS LocationKey,
    LSOACode,
    LSOAName,
    LocationDescription,
    Latitude,
    Longitude
FROM loc

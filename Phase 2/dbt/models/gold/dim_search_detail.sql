WITH search_detail AS (
    SELECT DISTINCT
        Legislation,
        ObjectOfSearch
    FROM {{ ref('stopsearch_clean') }}
    WHERE Legislation IS NOT NULL
)
SELECT
    row_number() OVER (ORDER BY Legislation, ObjectOfSearch) AS SearchDetailKey,
    Legislation AS LegislationUsed,
    ObjectOfSearch
FROM search_detail

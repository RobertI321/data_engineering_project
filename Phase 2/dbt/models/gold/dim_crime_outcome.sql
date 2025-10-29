WITH crime_outcome AS (
    SELECT DISTINCT
        OutcomeType
    FROM {{ ref('crime_clean') }}
    WHERE OutcomeType IS NOT NULL
)
SELECT
    row_number() OVER (ORDER BY OutcomeType) AS CrimeOutcomeKey,
    OutcomeType                               AS OutcomeName,
    if(OutcomeType ILIKE '%no%', 0, 1)        AS IsResolved
FROM crime_outcome

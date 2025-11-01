WITH crime_outcome AS (
    SELECT DISTINCT
        OutcomeType
    FROM {{ ref('crime_clean') }}
    WHERE trim(OutcomeType) != ''
)
SELECT
    row_number() OVER (ORDER BY OutcomeType) AS CrimeOutcomeKey,
    OutcomeType  AS OutcomeName,
    multiIf(
        OutcomeType ILIKE '%caution%', 1,
        OutcomeType ILIKE '%charge%', 1,
        OutcomeType ILIKE '%penalty%', 1,
        OutcomeType ILIKE '%local resolution%', 1,
        OutcomeType ILIKE '%summons%', 1,
        OutcomeType ILIKE '%community resolution%', 1,
        OutcomeType ILIKE '%another organisation%', 1,
        OutcomeType ILIKE '%under investigation%', 0,
        OutcomeType ILIKE '%no suspect%', 0,
        OutcomeType ILIKE '%awaiting%', 0,
        OutcomeType ILIKE '%unable to prosecute%', 0,
        OutcomeType ILIKE '%not in the public interest%', 0,
        0
    ) AS IsResolved 
FROM crime_outcome

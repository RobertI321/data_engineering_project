WITH outcomes AS (
    SELECT DISTINCT
        Outcome
    FROM {{ ref('stopsearch_clean') }}
    WHERE Outcome IS NOT NULL
)
SELECT
    row_number() OVER (ORDER BY Outcome) AS SearchOutcomeKey,
    Outcome AS OutcomeName,
    if(Outcome ILIKE '%no%', 0, 1) AS IsSuccessful
FROM outcomes

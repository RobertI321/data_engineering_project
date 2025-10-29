WITH demographics AS (
    SELECT DISTINCT
        Gender,
        AgeRange,
        EthnicitySelf,
        EthnicityOfficer
    FROM {{ ref('stopsearch_clean') }}
    WHERE Gender IS NOT NULL
)
SELECT
    row_number() OVER (ORDER BY Gender, AgeRange, EthnicitySelf, EthnicityOfficer) AS DemographicsKey,
    Gender,
    AgeRange,
    EthnicitySelf,
    EthnicityOfficer
FROM demographics

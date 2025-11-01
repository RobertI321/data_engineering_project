SELECT
    row_number() OVER () AS CrimeFactID, 
    c.CrimeID,
    dd.DateKey,
    dl.LocationKey,
    c.PoliceForce,
    c.CrimeType,
    dco.CrimeOutcomeKey,
    1 AS IncidentCount
FROM {{ ref('crime_clean') }} AS c
LEFT JOIN {{ ref('dim_date') }} AS dd
    ON toYYYYMMDD(dd.FullDate) = toYYYYMMDD(c.ReportedDate)
LEFT JOIN {{ ref('dim_location') }} AS dl
    ON dl.LSOACode = c.LSOACode
LEFT JOIN {{ ref('dim_crime_outcome') }} AS dco
    ON dco.OutcomeName = c.OutcomeType
WHERE c.CrimeID IS NOT NULL

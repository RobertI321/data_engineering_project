SELECT
    row_number() OVER () AS StopFactID,
    s.StopID,
    dd.DateKey,
    ddm.DemographicsKey,
    dso.SearchOutcomeKey,
    dsd.SearchDetailKey,
    s.IsLinkedToObject,
    1 AS StopCount
FROM {{ ref('stopsearch_clean') }} AS s
LEFT JOIN {{ ref('dim_date') }} AS dd
    ON dd.FullDate = toDate(s.Date)
LEFT JOIN {{ ref('dim_demographics') }} AS ddm
    ON ddm.Gender = s.Gender
    AND ddm.AgeRange = s.AgeRange
LEFT JOIN {{ ref('dim_search_outcome') }} AS dso
    ON dso.OutcomeName = s.Outcome
LEFT JOIN {{ ref('dim_search_detail') }} AS dsd
    ON dsd.LegislationUsed = s.Legislation
WHERE s.StopID IS NOT NULL

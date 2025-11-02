SELECT
    row_number() OVER () AS StopFactID,
    dd.DateKey,
    ddm.DemographicsKey,
    dl.LocationKey,
    dso.SearchOutcomeKey,
    dsd.SearchDetailKey,
    s.IsLinkedToObject,
FROM {{ ref('stopsearch_clean') }} AS s
LEFT JOIN {{ ref('dim_date') }} AS dd
    ON dd.FullDate = toDate(s.Date)
LEFT JOIN {{ ref('dim_demographics') }} AS ddm
    ON ddm.Gender = s.Gender
    AND ddm.AgeRange = s.AgeRange
    AND ddm.EthnicitySelf = s.EthnicitySelf
    AND ddm.EthnicityOfficer = s.EthnicityOfficer
LEFT JOIN {{ ref('dim_location') }} AS dl
    ON round(s.Latitude, 3) = dl.Latitude
    AND round(s.Longitude, 3) = dl.Longitude
LEFT JOIN {{ ref('dim_search_outcome') }} AS dso
    ON dso.OutcomeName = s.Outcome
LEFT JOIN {{ ref('dim_search_detail') }} AS dsd
    ON dsd.LegislationUsed = s.Legislation

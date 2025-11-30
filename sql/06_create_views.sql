-- Full-access view
DROP VIEW IF EXISTS ukpolice_gold.view_analysis_full;

CREATE VIEW ukpolice_gold.view_analysis_full AS
SELECT
    s.StopFactID,
    d.Year,
    d.Month,
    d.Day,
    d.Season,
    d.WeekDay,
    d.WeekdayType,
    d.Holiday,
    l.LSOACode,
    l.LSOAName,
    l.LocationDescription,
    de.Gender,
    de.AgeRange,
    de.EthnicityOfficer,
    so.OutcomeName AS Outcome,
    so.IsSuccessful,
    sd.ObjectOfSearch,
    s.IsLinkedToObject
FROM
    ukpolice_gold.fact_stop_search s
LEFT JOIN ukpolice_gold.dim_date d 
    ON s.DateKey = d.DateKey
LEFT JOIN ukpolice_gold.dim_location l
    ON s.LocationKey = l.LocationKey
LEFT JOIN ukpolice_gold.dim_demographics de
    ON s.DemographicsKey = de.DemographicsKey
LEFT JOIN ukpolice_gold.dim_search_outcome so
    ON s.SearchOutcomeKey = so.SearchOutcomeKey
LEFT JOIN ukpolice_gold.dim_search_detail sd
    ON s.SearchDetailKey = sd.SearchDetailKey;


 -- Limited-access table with pseudonymized columns (Gender, EthnicityOfficer, LSOACode, LSOAName, LSOALocationDescription)
DROP TABLE IF EXISTS ukpolice_gold.masked_analysis;

CREATE TABLE ukpolice_gold.masked_analysis
(
    StopFactID UInt64,
    Year Nullable(UInt16),
    Month Nullable(UInt8),
    Day Nullable(UInt8),
    Season Nullable(String),
    WeekDay Nullable(String),
    WeekdayType Nullable(String),
    Holiday Nullable(UInt8),
    LSOACode Nullable(String),
    LSOAName Nullable(String),
    LocationDescription Nullable(String),
    Gender Nullable(String),
    AgeRange Nullable(String),
    EthnicityOfficer Nullable(String),
    Outcome String,
    IsSuccessful UInt8,
    ObjectOfSearch Nullable(String),
    IsLinkedToObject String
)
ENGINE = MergeTree()
ORDER BY StopFactID;

INSERT INTO ukpolice_gold.masked_analysis
SELECT
    s.StopFactID,
    d.Year,
    d.Month,
    d.Day,
    d.Season,
    d.WeekDay,
    d.WeekdayType,
    d.Holiday,
    if(isNull(l.LSOACode), NULL, concat(substring(l.LSOACode, 1, length(l.LSOACode) - 1), '*')) AS LSOACode,
    if(isNull(l.LSOAName), NULL, concat(substring(l.LSOAName, 1, position(l.LSOAName, ' ')-1), ' ***')) AS LSOAName,
    if(isNull(l.LocationDescription), NULL, '***') AS LocationDescription,
    if(isNull(de.Gender), NULL, '***') AS Gender,
    de.AgeRange,
    if(isNull(de.EthnicityOfficer), NULL, '***') AS EthnicityOfficer,
    so.OutcomeName AS Outcome,
    so.IsSuccessful,
    sd.ObjectOfSearch,
    s.IsLinkedToObject
FROM
    ukpolice_gold.fact_stop_search s
LEFT JOIN ukpolice_gold.dim_date d 
    ON s.DateKey = d.DateKey
LEFT JOIN ukpolice_gold.dim_location l
    ON s.LocationKey = l.LocationKey
LEFT JOIN ukpolice_gold.dim_demographics de
    ON s.DemographicsKey = de.DemographicsKey
LEFT JOIN ukpolice_gold.dim_search_outcome so
    ON s.SearchOutcomeKey = so.SearchOutcomeKey
LEFT JOIN ukpolice_gold.dim_search_detail sd
    ON s.SearchDetailKey = sd.SearchDetailKey;


/*
-- Limited-access view with masked columns (Gender, EthnicityOfficer, LSOACode, LSOAName, LSOALocationDescription)
DROP VIEW IF EXISTS ukpolice_gold.view_analysis_masked;

CREATE VIEW ukpolice_gold.view_analysis_masked AS
SELECT
    s.StopFactID,
    d.Year,
    d.Month,
    d.Day,
    d.Season,
    d.WeekDay,
    d.WeekdayType,
    d.Holiday,
    if(isNull(l.LSOACode), NULL, concat(substring(l.LSOACode, 1, length(l.LSOACode) - 1), '*')) AS LSOACode,
    if(isNull(l.LSOAName), NULL, concat(substring(l.LSOAName, 1, position(l.LSOAName, ' ')-1), ' ***')) AS LSOAName,
    if(isNull(l.LocationDescription), NULL, '***') AS LocationDescription,
    if(isNull(de.Gender), NULL, '***') AS Gender,
    de.AgeRange,
    if(isNull(de.EthnicityOfficer), NULL, '***') AS EthnicityOfficer,
    so.OutcomeName AS Outcome,
    so.IsSuccessful,
    sd.ObjectOfSearch,
    s.IsLinkedToObject
FROM
    ukpolice_gold.fact_stop_search s
LEFT JOIN ukpolice_gold.dim_date d 
    ON s.DateKey = d.DateKey
LEFT JOIN ukpolice_gold.dim_location l
    ON s.LocationKey = l.LocationKey
LEFT JOIN ukpolice_gold.dim_demographics de
    ON s.DemographicsKey = de.DemographicsKey
LEFT JOIN ukpolice_gold.dim_search_outcome so
    ON s.SearchOutcomeKey = so.SearchOutcomeKey
LEFT JOIN ukpolice_gold.dim_search_detail sd
    ON s.SearchDetailKey = sd.SearchDetailKey;

*/
-- 1. Are some ethnic groups stopped more often than others?

SELECT dd.EthnicityOfficer,
       COUNT(fss.StopFactID) AS TotalStops
FROM ukpolice_gold.fact_stop_search fss
JOIN ukpolice_gold.dim_demographics dd 
ON fss.DemographicsKey = dd.DemographicsKey
GROUP BY dd.EthnicityOfficer
ORDER BY TotalStops DESC;

-- 2. What is the rate of justified searches for each ethnic group?

SELECT dd.EthnicityOfficer,
       ROUND(
        (SUM(CASE WHEN dso.IsSuccessful = TRUE THEN 1 ELSE 0 END) * 100.0) / 
        COUNT(DISTINCT fss.StopFactID), 1
       ) AS JustifiedSearchRatePercent
FROM ukpolice_gold.fact_stop_search fss
INNER JOIN ukpolice_gold.dim_demographics dd 
ON fss.DemographicsKey = dd.DemographicsKey
LEFT JOIN ukpolice_gold.dim_search_outcome dso 
ON fss.SearchOutcomeKey = dso.SearchOutcomeKey
GROUP BY dd.EthnicityOfficer
ORDER BY JustifiedSearchRatePercent DESC;

-- 3. How effective are stop-and-search operations in terms of yielding an outcome linked to the search objective, broken down by year and month?

SELECT formatDateTime(dd.FullDate, '%Y-%m') AS YearMonth,
       CAST(SUM(CASE WHEN dso.IsSuccessful = TRUE THEN 1 ELSE 0 END) AS DECIMAL) * 100 / 
            COUNT(fss.StopFactID) AS OverallSuccessfulOutcomeRate
FROM ukpolice_gold.fact_stop_search fss
LEFT JOIN ukpolice_gold.dim_date dd
ON fss.DateKey = dd.DateKey
JOIN ukpolice_gold.dim_search_outcome dso 
ON fss.SearchOutcomeKey = dso.SearchOutcomeKey
GROUP BY formatDateTime(dd.FullDate, '%Y-%m')
ORDER BY formatDateTime(dd.FullDate, '%Y-%m') DESC;

-- 4. Are there differences by location in terms of effective outcome (stop-and-search led to action)?
SELECT dl.LSOAName,
       COUNT(fss.StopFactID) AS TotalStops,
       CAST(SUM(CASE WHEN dso.IsSuccessful = TRUE THEN 1 ELSE 0 END) AS DECIMAL) * 100 / COUNT(fss.StopFactID) AS SuccessfulOutcomeRate
FROM ukpolice_gold.fact_stop_search fss
JOIN ukpolice_gold.dim_location dl 
    ON fss.LocationKey = dl.LocationKey
JOIN ukpolice_gold.dim_search_outcome dso 
    ON fss.SearchOutcomeKey = dso.SearchOutcomeKey
WHERE dl.LSOAName IS NOT NULL
GROUP BY dl.LSOAName
ORDER BY TotalStops DESC, SuccessfulOutcomeRate Desc;

-- 5. Are there certain months or seasons when crime and stop-and-search both increase?
WITH 
crime AS (
    SELECT 
        DateKey, 
        COUNT(DISTINCT CrimeFactID) AS TotalCrimeIncidents
    FROM ukpolice_gold.fact_crime
    GROUP BY DateKey
),
stops AS (
    SELECT 
        DateKey, 
        COUNT(DISTINCT StopFactID) AS TotalStopEvents
    FROM ukpolice_gold.fact_stop_search
    GROUP BY DateKey
)
SELECT 
    dd.Year,
    dd.MonthName,
    SUM(coalesce(crime.TotalCrimeIncidents, 0)) AS TotalCrimeIncidents,
    SUM(coalesce(stops.TotalStopEvents, 0)) AS TotalStopEvents
FROM ukpolice_gold.dim_date dd
LEFT JOIN crime ON dd.DateKey = crime.DateKey
LEFT JOIN stops ON dd.DateKey = stops.DateKey
GROUP BY dd.Year, dd.MonthName, dd.Month
ORDER BY dd.Year, dd.Month;

-- 6. What types of crimes are most commonly closed with no suspect identified?

SELECT
    fc.CrimeType,
    COUNTIf(dco.OutcomeName = 'Investigation complete; no suspect identified') AS UnresolvedCases,
    COUNT(fc.CrimeFactID) AS TotalCases,
    ROUND(COUNTIf(dco.OutcomeName = 'Investigation complete; no suspect identified') * 100.0 / COUNT(fc.CrimeFactID), 1) AS UnresolvedRatePercent
FROM ukpolice_gold.fact_crime fc
JOIN ukpolice_gold.dim_crime_outcome dco
    ON fc.CrimeOutcomeKey = dco.CrimeOutcomeKey
GROUP BY fc.CrimeType
ORDER BY UnresolvedRatePercent DESC;
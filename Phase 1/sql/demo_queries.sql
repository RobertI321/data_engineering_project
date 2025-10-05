-- =======================================================
-- Demo Queries
-- =======================================================

-- 1. Are some ethnic groups stopped more often than others?
SELECT
    DD.Ethnicity_Officer_Defined,
    COUNT(FS.Stop_ID) AS Total_Stops
FROM
    Fact_Stop_Search FS
JOIN
    Dim_Demographics DD 
        ON FS.DemographicsKey = DD.DemographicsKey
GROUP BY
    DD.Ethnicity_Officer_Defined
ORDER BY
    Total_Stops DESC;


-- 2. What is the rate of justified searches for each ethnic group?
-- A justified search is one that leads to criminal charges or other legal actions.
SELECT
    D.Ethnicity_Officer_Defined,
    ROUND(
        (SUM(CASE WHEN SO.Is_Successful = TRUE THEN 1 ELSE 0 END) * 100.0) /
        COUNT(DISTINCT FSS.Stop_ID),
        2
    ) AS Justified_Search_Rate_Percent
FROM
    Fact_Stop_Search FSS
INNER JOIN
    Dim_Demographics D 
        ON FSS.DemographicsKey = D.DemographicsKey
LEFT JOIN
    Dim_Search_Outcome SO 
        ON FSS.SearchOutcomeKey = SO.SearchOutcomeKey
GROUP BY
    D.Ethnicity_Officer_Defined
ORDER BY
    Justified_Search_Rate_Percent DESC;


-- 3. How effective are stop-and-search operations, in terms of yielding positive outcomes?
SELECT
    CAST(SUM(CASE WHEN DO.Is_Successful = TRUE THEN 1 ELSE 0 END) AS DECIMAL) * 100 /
    COUNT(FS.Stop_ID) AS Overall_Successful_Outcome_Rate
FROM
    Fact_Stop_Search FS
JOIN
    Dim_Search_Outcome DO 
        ON FS.SearchOutcomeKey = DO.SearchOutcomeKey;


-- 4. Are there differences by location in terms of effective outcomes?
-- (Stop-and-search led to action)
SELECT
    DL.LSOA_Name,
    COUNT(FS.Stop_ID) AS Total_Stops,
    CAST(SUM(CASE WHEN DO.Is_Successful = TRUE THEN 1 ELSE 0 END) AS DECIMAL) * 100 /
    COUNT(FS.Stop_ID) AS Successful_Outcome_Rate
FROM
    Fact_Stop_Search FS
JOIN
    Dim_Location DL 
        ON FS.LocationKey = DL.LocationKey
JOIN
    Dim_Search_Outcome DO 
        ON FS.SearchOutcomeKey = DO.SearchOutcomeKey
WHERE
    DL.LSOA_Name IS NOT NULL
GROUP BY
    DL.LSOA_Name
ORDER BY
    Successful_Outcome_Rate DESC;


-- 5. Are there certain months or seasons when crime and stop-and-search both increase?
SELECT
    DD.Year,
    DD.Month_Name,
    COUNT(FCI.Crime_ID) AS Total_Crime_Incidents,
    COUNT(FSS.Stop_ID) AS Total_Stop_Events
FROM
    Dim_Date DD
LEFT JOIN
    Fact_Crime_Incident FCI 
        ON DD.DateKey = FCI.DateKey
LEFT JOIN
    Fact_Stop_Search FSS 
        ON DD.DateKey = FSS.DateKey
GROUP BY
    DD.Year, DD.Month_Name
ORDER BY
    DD.Year, DD.Month_Name;


-- 6. What types of crimes are most commonly closed with no suspect identified?
SELECT
    DCT.Crime_Type_Name,
    COUNT(FCI.Crime_ID) AS Total_Unresolved_Cases
FROM
    Fact_Crime_Incident FCI
JOIN
    Dim_Crime_Type DCT 
        ON FCI.CrimeTypeKey = DCT.CrimeTypeKey
JOIN
    Dim_Outcome DO 
        ON FCI.OutcomeKey = DO.OutcomeKey
WHERE
    DO.Outcome_Name = 'Investigation complete; no suspect identified'
GROUP BY
    DCT.Crime_Type_Name
ORDER BY
    Total_Unresolved_Cases DESC;

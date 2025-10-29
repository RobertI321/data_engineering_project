WITH dates AS (
    SELECT DISTINCT toDate(ReportedDate) AS d
    FROM {{ ref('crime_clean') }}
    WHERE ReportedDate IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT toDate(Date) AS d
    FROM {{ ref('stopsearch_clean') }}
    WHERE Date IS NOT NULL
)
SELECT
    toUInt32(toYYYYMMDD(d)) AS DateKey,
    d AS FullDate,
    toYear(d) AS Year,
    toMonth(d) AS Month,
    toDayOfMonth(d) AS Day,
    formatDateTime(d, '%b') AS MonthName,
    if(toMonth(d) IN (12,1,2), 'Winter',
       if(toMonth(d) IN (3,4,5), 'Spring',
          if(toMonth(d) IN (6,7,8), 'Summer', 'Autumn'))) AS Season,
    formatDateTime(d, '%a') AS WeekDay,
    if(formatDateTime(d, '%a') IN ('Sat','Sun'), 'Weekend', 'Workday') AS WeekdayType,
    false AS Holiday
FROM dates


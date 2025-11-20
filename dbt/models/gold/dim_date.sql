WITH
-- Combine unique dates from both datasets
dates AS (
    SELECT DISTINCT toDate(ReportedDate) AS d
    FROM {{ ref('crime_clean') }}
    WHERE ReportedDate IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT toDate(Date) AS d
    FROM {{ ref('stopsearch_clean') }}
    WHERE Date IS NOT NULL
),

-- Define holidays by month-day pairs (universal)
uk_holidays AS (
    SELECT arrayJoin([
        (1, 1),   -- New Year’s Day
        (5, 1),   -- Early May Bank Holiday
        (8, 28),  -- Summer Bank Holiday
        (12, 25), -- Christmas Day
        (12, 26)  -- Boxing Day
    ]) AS md
)

-- Final select
SELECT
    toUInt32(toYYYYMMDD(d)) AS DateKey,
    d AS FullDate,
    toYear(d) AS Year,
    toMonth(d) AS Month,
    toDayOfMonth(d) AS Day,
    formatDateTime(d, '%b') AS MonthName,
    multiIf(
        toMonth(d) IN (12,1,2), 'Winter',
        toMonth(d) IN (3,4,5), 'Spring',
        toMonth(d) IN (6,7,8), 'Summer',
        'Autumn'
    ) AS Season,
    formatDateTime(d, '%a') AS WeekDay,
    if(toDayOfWeek(d) IN (6,7), 'Weekend', 'Workday') AS WeekdayType,

    -- Holiday flag: if month/day match any pattern
    if((toMonth(d), toDayOfMonth(d)) IN (SELECT * FROM uk_holidays),1,0) AS Holiday

FROM dates AS d



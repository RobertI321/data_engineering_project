SELECT
    cityHash64(
        coalesce(date, ''),
        coalesce(gender, ''),
        coalesce(age_range, ''),
        coalesce(legislation, ''),
        coalesce(object_of_search, ''),
        coalesce(outcome, ''),
        coalesce(self_defined_ethnicity, ''),
        coalesce(officer_defined_ethnicity, ''),
        toString(latitude),
        toString(longitude),
        coalesce(data_month, '')
    ) AS StopID,
    parseDateTimeBestEffortOrNull(date) AS Date,
    gender AS Gender,
    age_range AS AgeRange,
    self_defined_ethnicity AS EthnicitySelf,
    officer_defined_ethnicity AS EthnicityOfficer,
    legislation AS Legislation,
    object_of_search  AS ObjectOfSearch,
    outcome AS Outcome,
    outcome_linked_to_object_of_search AS IsLinkedToObject,
    latitude AS Latitude,
    longitude AS Longitude,
    data_month AS DataMonth
FROM {{ source('bronze','bronze_stopsearch_raw') }}
WHERE date IS NOT NULL


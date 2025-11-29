-- Query data from the full view by the full-access user
SET ROLE analyst_full;
SELECT * FROM ukpolice_gold.view_analysis_full LIMIT 5;
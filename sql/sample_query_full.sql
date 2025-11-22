-- Query data from full access view with full access user
SET ROLE analyst_full;
SELECT * FROM ukpolice_gold.view_analysis_full LIMIT 5;
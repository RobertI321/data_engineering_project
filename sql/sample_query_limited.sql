-- Query data from full and limited access view with limited access user
SET ROLE analyst_limited;
SELECT * FROM ukpolice_gold.view_analysis_full LIMIT 5;   -- should not give output

SET ROLE analyst_limited;
SELECT * FROM ukpolice_gold.view_analysis_limited LIMIT 5;
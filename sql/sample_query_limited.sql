-- Query data from the full view and the masked-view by a limited-access user
SET ROLE analyst_limited;
SELECT * FROM ukpolice_gold.view_analysis_full LIMIT 5;   -- should not give output

SET ROLE analyst_limited;
SELECT * FROM ukpolice_gold.view_analysis_masked LIMIT 5;
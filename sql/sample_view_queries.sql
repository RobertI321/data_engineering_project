SET ROLE analyst_full;
SELECT * FROM ukpolice_gold.view_analysis_full LIMIT 5;

SET ROLE analyst_limited;
SELECT * FROM ukpolice_gold.view_analysis_full LIMIT 5;   -- should not give output

SET ROLE analyst_limited;
SELECT * FROM ukpolice_gold.view_analysis_limited LIMIT 5;
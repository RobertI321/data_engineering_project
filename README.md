# Crime and Stop-and-Search Analytics

## Overview
This project looks at how crime incidents and stop-and-search activity relate to each other in London. By bringing these two datasets together, it becomes possible to see patterns across areas and groups, check how effective searches are, and highlight when and where activity increases. The results can help police and councils with planning, reporting, and safety work.

## Key Objectives
- Combine crime and stop-and-search data into one view.  
- Measure how often searches lead to useful outcomes.  
- Spot differences across neighbourhoods, ethnic groups, and time periods.  
- Create a base for dashboards and reports that support decision making.  

---

## Datasets
Two public datasets from the [UK Police Data Portal](https://data.police.uk/data/) are used. Both are updated every month.

### Crime data
- Records individual crime and anti-social behaviour incidents.  
- Includes when and where an incident happened, what type it was, and its last known outcome.  
- Location information is given at street or small-area level (LSOA).  

### Stop-and-search data
- Records police stop-and-search activity.  
- Includes the date, location, reason for the search, demographics of the person stopped, and the outcome.  
- Also shows whether the outcome was linked to the original reason for the search.  

---

## Workflow
1. **Collect** – Data is downloaded each month from the portal (CSV or API).  
2. **Store** – Data is kept in PostgreSQL, running in Docker.  
3. **Schedule** – Airflow is used to handle monthly updates.  
4. **Transform** – dbt prepares clean tables and builds a star schema for analysis.  
5. **Analyze** – ClickHouse is used for fast queries across large volumes.  
6. **Visualize** – Apache Superset presents dashboards and KPIs to answer key questions.  


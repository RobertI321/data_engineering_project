# Project 2. Data warehouse implementation, ETL pipelines
In this phase, we implement a working data pipeline that ingests, transforms, and loads data into an analytical warehouse. 

The project uses the following technologies:
- **Apache Airflow** to orchestrate and schedule data pipeline.
- **ClickHouse** for analytical storage.
- **dbt** for making data transformations.
- **Docker** to containerize services and ensure the environment is consistent and reproducible across different machines.

The goal is to build an automated pipeline that ensures data is clean, transformed, and available for analytics.

---

## Table of Contents
- [Overview](#overview)
- [Services](#services)
- [Project structure](#project-structure)
- [Environment setup](#environment_setup)
- [Airflow DAGs](#airflow-dags)
- [Analytical queries](#analytical-queries)

---

## Overview
Two data sources are used for **street-level crime** and **stop and search** data for London from [data.police.uk.](https://data.police.uk/): 
- downloadable CSV files
- API for metadata (available months)

The ingested raw data will be loaded into ClickHouse Bronze layer. The Silver layer contains cleaned data, the Gold layer includes transformed data modeled according to the dimensional model using dbt.

Business questions are answered by querying the Gold layer in ClickHouse.

---

## Project structure
```text
Phase 2/
├── .env
├── airflow-docker/
|   ├── configs/
│   ├── dags/
│   └── docker-compose.yaml
├── clickhouse/
|   └── queries.sql
├── dbt/
|    ├── models/
|    ├── dbt_project.yml
|    └── profiles.yml
└── images/
    └── airflow_dags.png
```
---

## Services
The project includes a ready-to-run Docker Compose setup with the following services:
- **Airflow Webserver** for monitoring and managing pipelines.
- **Airflow Scheduler** to schedule and trigger DAGs.
- **Postgres** serves as the Airflow metadata database and staging area.
- **pgAdmin** for managing the Postgres database.
- **ClickHouse** as the analytical warehouse.
- **dbt** to transform data from the Bronze to the Gold layer.
---

## Environment setup
Step-by-step instructions to get the project running locally.

> :heavy_check_mark: All login credentials are in .env file.

**1. Create a project folder locally** where to clone the Git repository

**2. Navigate into the project folder and clone the repository**:

```bash
cd your_project_folder

git clone https://github.com/RobertI321/data_engineering_project.git
```
**3. Start the services** using "docker-compose.yaml" in the airflow-docker folder:
> :warning: Make sure that Docker is running before starting the project.
```bash
cd "data_engineering_project/Phase 2/airflow-docker"
docker compose up -d
```
**4. Connect to pgAdmin** and create a new server:
1. Acces pgAdmin at [http://localhost:5050](http://localhost:5050)
2. Register a new server
    - Name: server
    - Host name: project-db
    - Port: 5432
    - Maintenace databse: project_db
    - Username and password: in .env file

**5. Connect to Airflow UI:**
1. Access Airflow at [http://localhost:8080](http://localhost:8080)
2. To ingest raw data into the staging layer in the Postgres database, run the DAG **police_data_ingestion**.
3. To move data into the ClickHouse Bronze layer, run the DAG **move_data_to_clickhouse**.

**6. Connect to ClickHouse:**
1. Access ClickHouse UI at [http://localhost:8123/play](http://localhost:8123/play)
or via Docker:

```bash
docker exec -it clickhouse-project2 clickhouse-client
```
2. Query data from ClickHouse Bronze layer:
```bash
USE bronze;
SHOW TABLES;
SELECT * FROM bronze_crime_raw LIMIT 10;
```
3. Query data from ClickHouse Silver layer:
```bash
USE ukpolice_silver;
SHOW TABLES;
SELECT * FROM crime_clean LIMIT 10;
```
4. Query data from ClickHouse Silver layer:
```bash
USE ukpolice_gold;
SHOW TABLES;
SELECT * FROM dim_date LIMIT 10;
SELECT * FROM fact_crime LIMIT 10;
```

---

## Airflow DAGs

The DAGs can be managed through the Airflow Web UI:

![Airflow DAGs](images/airflow_dags.png)

- **police_data_ingestion**:
    - automates the ingestion of police crime and stop-and-search data for the Cambridgeshire region from the [UK Police data service](https://data.police.uk/)
    - retrieves metadata (available months) via the API and downloads the corresponding montly data archive as zipped CSV files
    - scheduled to run monthly, as new data becomes available each month
    - loads the latest month's raw data into Postgres database (staging)
    - ensures idempotent loading - already ingested months are skipped to prevent duplicates. 

- **move_data_to_clickhouse**
    - transfers raw data from Postgres staging area into the ClickHouse Bronze layer
    - run manually after raw data has been successfully ingested
    - ensures idempotent loading - deletes existing data for a given month, and removes rows for the same month before reloading
    - executes dbt models using the newly loaded data, transforming it into the Silver and Gold layers in ClickHouse
    - runs dbt tests (validations, e.g., unique and not null constraints) to verify data quality
    - dbt tasks are dependent on loading data: all load tasks must be completed before dbt transformations start.

## Analytical queries

Business questions from Project 1 are answered using data in the Gold layer. SQL queries are in project folder Phase 2/ClickHouse/queries.sql.

1. Are some ethnic groups stopped more often than others?

| EthnicityOfficer | TotalStops | 
|:-----------------|-----------:|
| White            | 274        |
| Asian            | 34         |
| Black            | 15         |
| Other            | 11         |
|                  | 11         |

2. What is the rate of justified searches for each ethnic group? 
    - A justified search is one that leads to criminal charges or other legal actions.

| EthnicityOfficer | JustifiedSearchRatePercent | 
|:-----------------|---------------------------:|
| Asian            | 45                         |
| Black            | 41.2                       |
| Other            | 39.3                       |
| White            | 34.2                       |
|                  | 28.6                       |

3. How effective are stop-and-search operations, in terms of yielding an outcome linked to the search objective?

| YearMonth | OverallSuccessfulOutcomeRate | 
|:----------|-----------------------------:|
| 2025-08   | 35                           |

4. Are there differences by area in terms of effective outcome (stop-and-search led to action)?

| LSOAName           | TotalStops | SuccessfulOutcomeRate |
|:-------------------|-----------:|----------------------:|
| Cambridge 007J     | 31         | 0                     |
| Cambridge 007H     | 21         | 0                     |
| Peterborough 014A  | 19         | 47                    |
| Peterborough 014D  | 9          | 100                   |
| Peterborough 014G  | 9          | 100                   |
| Peterborough 011C  | 9          | 11                    |
| ...                | ...        | ...                   |

5. Are there certain months or seasons when crime and stop-and-search both increase?

| Year           | MonthName | TotalCrimeIncidents | TotalStopEvents |
|:---------------|----------:|--------------------:|----------------:|
| 2025           | Aug       | 71368               | 622             |    

6. What types of crimes are most commonly closed with no suspect identified?

| CrimeType                     | UnresolvedCases | TotalCases | UnresolvedRatePercent |
|:------------------------------|----------------:|-----------:|----------------------:|
| Bicycle theft                 | 1470            | 1639       | 89.7                  |
| Theft from the person         | 945             | 1085       | 87.1                  |
| Vehicle crime                 | 2210            | 3192       | 69.2                  |
| Other theft                   | 2963            | 4803       | 61.7                  |
| ...                           | ...             | ...        | ...                   |
| Violence and sexual offences  | 3489            | 24258      | 14.4                  |
| Other crime                   | 148             | 1761       | 8.4                   |
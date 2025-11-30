# 1. Crime and Stop-and-Search Analytics
## Table of Contents
- [Overview](#overview)
- [Key Objectives](#key-objectives)
- [Datasets](#datasets)
  - [Crime data](#crime-data)
  - [Stop and search data](#stop-and-search-data)
- [Workflow](#workflow)
- [Project structure](#project-structure)

---
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

### Stop and search data
- Records police stop-and-search activity.  
- Includes the date, location, reason for the search, demographics of the person stopped, and the outcome.  
- Also shows whether the outcome was linked to the original reason for the search.  

---

## Workflow
1. **Collect** – Data is downloaded each month from the portal (CSV or API).  
2. **Store** – Data is kept in ClickHouse, running in Docker.  
3. **Schedule** – Airflow is used to handle monthly updates.  
4. **Transform** – dbt prepares clean tables and builds a star schema for analysis.  
5. **Analyze** – ClickHouse is used for fast queries across large volumes.  
6. **Visualize** – Apache Superset presents dashboards and KPIs to answer key questions.  

---
## Project structure
```text
.env
docker-compose.yml
airflow/
├── dags/
└── scripts/
archive/
└── ...
data/
├── 2025-07-cambridgeshire-stop-and-search_sample_data.csv
└── 2025-07-cambridgeshire-streets_sample_data.csv
dbt/
├── models/
|   ├── dbt_project.yml
|   ├── profiles.yml
|   ├── gold/
|   |   └── ...
|   ├── silver/
|   |   └── ...
|   └── sources/
|       └── ...
diagrams/
└── ...
docs/
└── metadata.json
images/
└── ...
minio/
└── iceberg-policy.json
sql/
├── 01_create_bronze_tables.sql
├── 02_make_iceberg_table_queriable.sql
├── 03_star_schema.sql
├── 04_analytical_queries.sql
├── 05_create_roles.sql
├── 06_create_views.sql
├── 07_sample_query_limited.sql
└── 08_sample_query_full.sql
superset/
├── Dockerfile.superset
└── superset_config.py
```
---

# 2. Data warehouse implementation, ETL pipelines*
#### * Project 2 updated to comply with changes made in Project 3.
## Table of Contents
- [Overview](#overview-1)
- [Services](#services)
- [Environment setup](#environment_setup)
- [Airflow DAGs](#airflow-dags)
- [Analytical queries](#analytical-queries)

---

## Overview

In this phase, we implement a working data pipeline that ingests, transforms, and loads data into an analytical warehouse. 

The project uses the following technologies:
- **Apache Airflow** to orchestrate and schedule data pipeline.
- **ClickHouse** for analytical storage.
- **dbt** for making data transformations.
- **Docker** to containerize services and ensure the environment is consistent and reproducible across different machines.

The goal is to build an automated pipeline that ensures data is clean, transformed, and available for analytics.

Two data sources are used for **street-level crime** and **stop and search** data for London from [data.police.uk.](https://data.police.uk/): 
- downloadable CSV files
- API for metadata (available months)

The ingested raw data will be loaded into ClickHouse Bronze layer. The Silver layer contains cleaned data, the Gold layer includes transformed data modeled according to the dimensional model using dbt.

Business questions are answered by querying the Gold layer in ClickHouse.

---

## Services
The project includes a ready-to-run Docker Compose setup with the following services:
- **Airflow Webserver** for monitoring and managing pipelines.
- **Airflow Scheduler** to schedule and trigger DAGs.
- **Postgres** serves as the Airflow metadata database.
- **pgAdmin** for managing the Postgres database.
- **ClickHouse** as the analytical warehouse.
- **dbt** to transform data from the Bronze to the Gold layer.
- **MinIO** for storing Iceberg tables in an S3-compatible object store.
- **Apache Iceberg** as the table format for versioned and ACID-compliant data storage.
- **OpenMetadata** for cataloging data assets, lineage, and running data quality tests.
- **Superset** for building and viewing analytical dashboards.
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
cd "data_engineering_project"
docker compose docker-compose.yaml --build -d
```
**4. Connect to pgAdmin (optional)** and create a new server:
1. Acces pgAdmin at [http://localhost:5050](http://localhost:5050)
2. Register a new server
    - Name: server
    - Host name: project-db
    - Port: 5432
    - Maintenace databse: project_db
    - Username and password: in .env file

**5. Connect to Airflow UI:**
1. Access Airflow at [http://localhost:8080](http://localhost:8080)
2. To initiate the ETL process, run the DAG **police_data_ingestion**.
3. To create Iceberg table, run the DAG **iceberg_crime_summary**.

**6. Connect to ClickHouse:**
1. Access ClickHouse UI at [http://localhost:8123/play](http://localhost:8123/play)
or via Docker:

```bash
docker exec -it clickhouse-server clickhouse-client
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
4. Query data from ClickHouse Gold layer:
```bash
USE ukpolice_gold;
SHOW TABLES;
SELECT * FROM dim_date LIMIT 10;
SELECT * FROM fact_crime LIMIT 10;
```

---

## Airflow DAGs

The DAGs can be managed through the Airflow Web UI:

![Airflow DAGs](images/airfllow_dags.png)

- **police_data_ingestion**:
    - automates the ingestion of police crime and stop-and-search data for the Cambridgeshire region from the [UK Police data service](https://data.police.uk/)
    - retrieves metadata (available months) via the API and downloads the corresponding montly data archive as zipped CSV files
    - scheduled to run monthly, as new data becomes available each month
    - loads the latest month's raw data into ClickHouse Bronze layer
    - ensures idempotent loading - deletes existing data for a given month, and removes rows for the same month before reloading
    - executes dbt models using the newly loaded data, transforming it into the Silver and Gold layers in ClickHouse
    - runs dbt tests (validations, e.g., unique and not null constraints) to verify data quality
    - dbt tasks are dependent on loading data: all load tasks must be completed before dbt transformations start.

    ![dag_model1](images/dag_model1.png)

-    **iceberg_crime_summary**:
    - Reads raw crime data from ClickHouse and aggregates it into monthly crime counts.
    - Converts the summarized data into a PyArrow table and writes it into an Iceberg table stored in MinIO.
    - If the Iceberg table already exists, the DAG recreates it and appends the latest processed data.


---

## Analytical queries

Business questions from Project 1 are answered using data in the Gold layer. SQL queries are in project folder sql/queries.sql.

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

---

# 3. Data governance and visualization
## Table of Contents
- [Overview](#overview-2)
- [Environment setup](#environment-setup-1)
- [Apache Iceberg](#apache-iceberg)
- [Clickhouse](#clickhouse)
- [OpenMetadata](#openmetadata)
- [Apache Superset](#apache-superset)

---
## Overview
This part of the project focuses on **data governance, security and privacy, and modern data analytics**, using Apache Iceberg and Apache Superset, on top of that work.

A new DAG in Airflow **iceberg_crime_summary** writes summarized crime data into an Iceberg table on MinIO. A MinIO bucket iceberg-bucket is automatically created.

---
## Environment setup
**1. Start services**:
At first, make sure you have followed the steps provided in the previous [environment setup](#environment-setup) paragraph.

**2. Using MinIO UI**:
    Minio setup is automated via scripts. In case the scripts should fail, log in and create "iceberg-bucket" manually:

- Login: http://localhost:9001


---
## Querying Iceberg tables

```bash
SELECT *
FROM iceberg.`bronze.crime_summary`
LIMIT 10;
```
![alt text](images/iceberg_query.png)

---
## ClickHouse
**Two roles** are created with different privileges: one for the analyst with **full access** to Gold layer tables, the other one for the **limited-access** analyst who can query a table based on Gold layer tables which has some columns masked.

All necessary sql scripts are in the **sql** folder.

**1. Load .env variables for using with sql scripts**

In PowerShell:
```bash
# Load .env variables
Get-Content .env | ForEach-Object {
    if ($_ -and $_ -notmatch '^#') {
        $parts = $_ -split '=', 2
        if ($parts.Length -eq 2) {
            [System.Environment]::SetEnvironmentVariable($parts[0], $parts[1], "Process")
        }
    }
```

**2. Create full and limited-access roles and users, and grant access to users**

Read SQL file and replace placeholders:
```bash
$sql = Get-Content ./sql/05_create_roles.sql -Raw
$sql = $sql -replace '\{full_pwd:String\}', "'$env:CLICKHOUSE_PASSWORD_FULL'"
$sql = $sql -replace '\{limited_pwd:String\}', "'$env:CLICKHOUSE_PASSWORD_LIMITED'"
```

Create roles and users, and grant access:
```bash
$sql | docker exec -it clickhouse-server clickhouse-client
```

**3. Create a full view, and table with masked columns on top of the Gold layer tables**

```bash
docker exec -it clickhouse-server clickhouse-client --multiquery --queries-file=/sql/06_create_views.sql
```

**4. Query the data with different roles**

The limited-access user should not get any results when querying the Gold layer tables or the view that is meant for the full-acces role.

**Login as limited-access user** (terminal asks for password):
```bash
docker exec -it clickhouse-server clickhouse-client -u limited_user --password $env:CLICKHOUSE_PASSWORD_LIMITED
```

Have a look at the Gold layer tables:
```bash
USE ukpolice_gold;
SHOW TABLES;
```

![query1](images/query1.png)

As you can see, the user with limited access can't even see the names of the tables and views which he doesn't have access.

Query a Gold layer table or a full-access view:
```bash
SELECT * 
FROM ukpolice_gold.view_analysis_full
LIMIT 5;
```

![query2](images/query2.png)

Query a Gold layer table that the user has access to:
```bash
SELECT StopFactID, Year, Month, Day, LSOACode, LSOAName, LocationDescription, Gender, EthnicityOfficer, Outcome, IsSuccessful
FROM ukpolice_gold.masked_analysis
LIMIT 5
FORMAT Pretty;
```

![query3](images/query3.png)

Now, the user sees the query results. The columns Gender, EthnicityOfficer, and columns related to location are masked.


**Login as full-access user** (terminal asks for password):
```bash
docker exec -it clickhouse-server clickhouse-client -u full_user --password $env:CLICKHOUSE_PASSWORD_FULL
```

Have a look at the Gold layer tables:
```bash
USE ukpolice_gold;
SHOW TABLES;
```

![query4](images/query4.png)

The full-access user sees all the tables and views from the Gold layer.

Query a Gold layer table or a full-access view:
```bash
SELECT StopFactID, Year, Month, Day, LSOACode, LSOAName, LocationDescription, Gender, EthnicityOfficer, Outcome, IsSuccessful
FROM ukpolice_gold.view_analysis_full
LIMIT 5
FORMAT Pretty;
```

![query5](images/query5.png)

This user sees the unmasked data. The query selects only some columns because the size of the table.

---
## OpenMetadata

### 4.1 Register ClickHouse Service

1. Open the OpenMetadata UI:  
   **http://localhost:8585**

2. Log in using the default credentials:  
   - **Email:** `admin@open-metadata.org`  
   - **Password:** `admin`

3. Navigate to:  
   **Settings → Services → Databases**

4. Click **Add Service** and select **ClickHouse**

5. Fill in the connection details:

   - **Service Name:** `clickhouse`
   - **Host:** `clickhouse-server`
   - **Port:** `8123`
   - **Username:** `default`
   - **Password:** `clickhouse_pass`
   - **Database:** `default`

6. Click **Test Connection** and wait for a **SUCCESS** result.

7. Click **Save** to register the service.

8. Add table and column descriptions

    **Example: Table description**
    ![tabledescription](images/table_description.png)

    **Example: Fact table column descriptions**
    ![factstopsearch1](images/fact_stop_search1.png)

    ![factstopsearch2](images/fact_stop_search2.png)

9. Add data quality tests

    **1. Not-Null Test (Fact Table Foreign Key)**
    Validates that every record in the fact table contains a non-null `LocationKey`, ensuring all events are linked to a location dimension record.
    ![testnotnull](images/test_not_null.png)

    **2. Unique Test (Dimension Surrogate Key)**
    Ensures that the `LocationKey` column in the location dimension contains only unique values with no duplicates.
    ![testunique](images/test_unique.png)

    **3. Additional Test — Holiday Indicator Validation**
    Checks that the `Holiday` column in the date dimension contains only valid indicator values (`0` or `1`).
    ![testholiday](images/test_holiday.png)

    **4. Test Execution Results**
    ![test_results](images/tests_all.png)

---
## Apache Superset

1. Open the Superset UI:  
   **http://localhost:8088**

2. Log in using the default credentials:  
   - **Username:** `admin`  
   - **Password:** `admin`

3. **Click + Database to add a new connection.**

4. **Select ClickHouse from the list of database types.**

5. Fill in the SQLAlchemy connection string:
    **clickhouse+http://default:clickhouse_pass@clickhouse-server:8123/default**

6. Create charts and dashboards
    ![alt text](images/superset_dash.png)

7. Register the dashboard in OMD
    ![alt text](images/OMD_superset.png)
---


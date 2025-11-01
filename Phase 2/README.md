# Project 2. Data warehouse implementation, ETL pipelines
In this phase, we implement a working data pipeline that ingests, transforms, and loads data into an analytical warehouse. 

The project uses the following technologies:
- **Apache Airflow** to orchestrate and schedule data pipeline.
- **Clickhouse** for analytical storage.
- **dbt (Data Build Tool)** for making data transformations.
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
Two data sources are used for **street-level crime** and **stop and search** data for London: 
- downloadable CSV files
- API from [data.police.uk.](https://data.police.uk/)

The ingested raw data will be loaded into Clickhouse Bronze layer. The Silver layer contains cleaned data, the Gold layer includes transformed data modeled according to the dimensional model using dbt.

...

---

## Project structure
```bash
Phase 2/
├── .env
├── airflow-docker/
|   ├── configs
│   ├── dags/
│   └── docker-compose.yaml
└── dbt/
    ├── models/
    ├── dbt_project.yml
    └── profiles.yml
```
---

## Services
The project includes a ready-to-run Docker Compose setup with the following services:
- **Airflow Webserver** for monitoring and managing pipelines.
- **Airflow Scheduler** to schedule and trigger DAGs.
- **Postgres** serves as the Airflow metadata database and staging area.
- **pgAdmin** for managing the Postgres database.
- **Clickhouse** as the analytical warehouse.
- **dbt** to transform data from the Bronze to the Gold layer.
---

## Environment setup
Step-by-step instructions to get the project running locally.

> :heavy_check_mark: <span style="color:red">All login credentials are in .env file.</span>

**1. Create a project folder locally** to clone the Git repository

**2. Clone the repository** and navigate into the project folder:

```bash
git clone https://github.com/RobertI321/data_engineering_project.git

cd data_engineering_project
```
**3. Start the services:**
> :warning: Make sure that Docker is running before starting the project.
```bash
docker compose up -d
```
**4. Connect to Airflow UI:**

1. Access Airflow at [http://localhost:8080](http://localhost:8080)
2. To ingest raw data into the staging layer in the Postgres database, run the DAG **police_data_ingestion**.
3. To move data into the Clickhouse Bronze layer, run the DAG **move_data_to_clickhouse**.
---

## Airflow DAGs

<span style="color:red">screenshots, etc</span>


## Analytical queries

<span style="color:red">Revised business questions</span> from Project 1 are answered using dbt models and queries:

1. Are some ethnic groups stopped more often than others?
2. What is the rate of justified searches for each ethnic group? 
    - A justified search is one that leads to criminal charges or other legal actions.
3. How effective are stop-and-search operations, in terms of yielding an outcome linked to the search objective?
4. Are there differences by area in terms of effective outcome (stop-and-search led to action)?
5. Are there certain months or seasons when crime and stop-and-search both increase?
6. What types of crimes are most commonly closed with no suspect identified?
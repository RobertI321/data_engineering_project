from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import psycopg2
from clickhouse_connect import get_client
import pandas as pd
import os
import json

def extract_from_postgres(table_name, query, **context):

    # Establish a connection to Postgres
    conn = psycopg2.connect(
        dbname="project_db",
        user="project_user",
        password="project_pass",
        host="project-db",
        port="5432"
    )

    df = pd.read_sql_query(query, conn)
    print(f"Extracted {len(df)} rows from Postgres table '{table_name}'")

    conn.close()
    
    # All rows NaNs check

    all_nan_rows = df[df.isna().all(axis=1)]
    nan_count = len(all_nan_rows)
    if nan_count > 0:
        print(f"Found {nan_count} rows with all NaN values in '{table_name}'. Removing them.")
        df.dropna(how='all', inplace=True)
    
    file_path = f"/tmp/{table_name}.csv"
    df.to_csv(file_path, index=False)
    print(f"Data from table '{table_name}' written to {file_path}, rows: {len(df)}")
    
    # Share file path via XCom (Share data between tasks)
    context['ti'].xcom_push(key=f"{table_name}_file", value=file_path)


def load_to_clickhouse(table_name, schema_sql, **context):

    # Establish a connection to Clickhouse
    client = get_client(
        host='clickhouse-project2',
        port='8123',
        user='default',
        password='clickhouse_pass',
        )

    # Create db - bronze layer if not exists
    client.command("CREATE DATABASE IF NOT EXISTS bronze")
    # Create table if needed
    client.command(schema_sql)

    # Load the extracted CSV file path from XCom
    file_path = context["ti"].xcom_pull(task_ids=f"extract_{table_name}", key=f"{table_name}_file")
    df = pd.read_csv(file_path)

    print("DATAFRAME DF TYPES:", df.dtypes)
    print("CLICKHOUSE TABLE SCHEMA:", client.command("DESCRIBE TABLE bronze.bronze_crime_raw"))

    # Add full table name with schema prefix
    full_table_name = f"bronze.{table_name}"

    for col, dtype in df.dtypes.items():
        if dtype == 'object':
            df[col] = df[col].fillna('').astype(str)


# Idempotency: remove rows for the same data_month before reloading
    months = df['data_month'].unique().tolist()
    for month in months:
        client.command(f"ALTER TABLE {full_table_name} DELETE WHERE data_month = '{month}'")

    

    # Insert data into Clickhouse
    client.insert_df(full_table_name, df)
    print(f"Loaded {len(df)} rows into Clickhouse table '{full_table_name}'")


with DAG(
    dag_id = "move_data_to_clickhouse",
    start_date = datetime(2025, 1, 1),
    schedule_interval = None, # Only run manually
    catchup = False,
) as dag:
    
    configs_path = "/opt/airflow/configs/bronze_tables.json"
    
    if not os.path.exists(configs_path):
        raise FileNotFoundError(f"Configuration file not found: {configs_path}")
    
    with open(configs_path, 'r') as f:
        table_configs = json.load(f)

    for table_name, config in table_configs.items():

        extract = PythonOperator(
            task_id=f"extract_{table_name}",
            python_callable=extract_from_postgres,
            op_kwargs={
                "table_name": table_name,
                "query": config["query"],
            },
            provide_context=True,
        )

        load = PythonOperator(
            task_id=f"load_{table_name}",
            python_callable=load_to_clickhouse,
            op_kwargs={
                "table_name": table_name,
                "schema_sql": config["schema"],
            },
            provide_context=True,
        )

        extract >> load

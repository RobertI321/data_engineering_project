from airflow.utils.dates import days_ago
from airflow import DAG
from airflow.operators.python import PythonOperator

import os
import pyarrow as pa
from clickhouse_connect import get_client

from pyiceberg.catalog import load_catalog
from pyiceberg.schema import Schema
from pyiceberg.types import NestedField, StringType, LongType
from pyiceberg.exceptions import TableAlreadyExistsError


def create_iceberg_table():

    # 1.Read data
    client = get_client(
        host="clickhouse-server",
        port=8123,
        username=os.getenv("CLICKHOUSE_USER"),
        password=os.getenv("CLICKHOUSE_PASSWORD"),
    )

    df = client.query_df("""
        SELECT month, crime_type, COUNT(*) AS total
        FROM bronze.bronze_crime_raw
        GROUP BY month, crime_type
    """)

    print(f"Rows fetched from CH: {len(df)}")

    pa_table = pa.Table.from_pandas(df)

    # 2. Connect to Iceberg 
    catalog = load_catalog(
        "rest",
        uri="http://iceberg_rest:8181",
        warehouse="s3://iceberg-bucket/",
        **{
            "s3.access-key-id": os.getenv("MINIO_ROOT_USER"),
            "s3.secret-access-key": os.getenv("MINIO_ROOT_PASSWORD"),
            "s3.endpoint": "http://minio:9000",
            "s3.region": "us-east-1",
            "s3.path-style-access": True,
        }
    )


    # 3. Define schema
    schema = Schema(
        NestedField(1, "month", StringType()),
        NestedField(2, "crime_type", StringType()),
        NestedField(3, "total", LongType()),
    )

    table_name = "bronze.crime_summary"

    print("Successfully loaded catalog object.")

    # Create namespace if missing
    try:
        catalog.create_namespace("bronze")
    except Exception:
        pass
    # Add a success print if this line is reached
    print("DEBUG: Successfully loaded catalog object2.")

    # 4. Create table OR overwrite it
    try:
        catalog.create_table(identifier=table_name, schema=schema)
        print("Created Iceberg table:", table_name)

    except TableAlreadyExistsError:
        print("Table exists, dropping and recreating...")
        catalog.drop_table(identifier=table_name)
        catalog.create_table(identifier=table_name, schema=schema)

    # Load table to append data
    table = catalog.load_table(table_name)
    table.append(pa_table)

    print("Data successfully written to Iceberg:", table_name)


# Airflow DAG
with DAG(
    dag_id="iceberg_crime_summary",
    schedule_interval=None,
    start_date=days_ago(1),
    catchup=False,
    description="Write summarized crime data into an Iceberg table on MinIO",
    tags=["iceberg", "minio", "clickhouse"],
) as dag:

    PythonOperator(
        task_id="create_iceberg_table",
        python_callable=create_iceberg_table
    )

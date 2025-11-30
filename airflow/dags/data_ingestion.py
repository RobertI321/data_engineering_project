from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago
from airflow.exceptions import AirflowSkipException
from clickhouse_connect import get_client
import requests
import zipfile
import io
import pandas as pd
import os
from airflow.operators.bash import BashOperator


# --- Config ---
FORCE = "cambridgeshire"
API_DATES = "https://data.police.uk/api/crimes-street-dates"
ARCHIVE_URL = "https://data.police.uk/data/archive/{month}.zip"

# Directory for temp files (tmpfs in docker-compose)
TMP_DIR = "/opt/airflow/tmp"



# -- Functions --

# Helper function to fix datatypes for crimes data (clickhouse load)
def fix_crime_types(df: pd.DataFrame) -> pd.DataFrame:
    string_cols = [
        "crime_id", "month", "reported_by", "falls_within",
        "location", "lsoa_code", "lsoa_name", "crime_type",
        "last_outcome_category", "data_month"
    ]

    numeric_cols = ["longitude", "latitude", "context"]

    # Create missing columns (in case source data csv columns should change)
    for col in string_cols:
        if col not in df.columns:
            df[col] = ""

    for col in numeric_cols:
        if col not in df.columns:
            df[col] = 0.0

    # Cast types
    for col in df.columns:
        if col in string_cols:
            df[col] = df[col].fillna("").astype(str)
        elif col in numeric_cols:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    return df

# Helper function to fix datatypes for stop-and-search data (clickhouse load)
def fix_stopsearch_types(df: pd.DataFrame) -> pd.DataFrame:
    string_cols = [
        "type", "date", "part_of_a_policing_operation", "gender",
        "age_range", "self_defined_ethnicity", "officer_defined_ethnicity",
        "legislation", "object_of_search", "outcome",
        "outcome_linked_to_object_of_search",
        "removal_of_more_than_just_outer_clothing",
        "data_month"
    ]

    numeric_cols = ["longitude", "latitude", "policing_operation"]

    # Create missing columns (in case source data csv columns should change)
    for col in string_cols:
        if col not in df.columns:
            df[col] = ""

    for col in numeric_cols:
        if col not in df.columns:
            df[col] = 0.0

    # Cast types
    for col in df.columns:
        if col in string_cols:
            df[col] = df[col].fillna("").astype(str)
        elif col in numeric_cols:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    return df

# Helper to clean column names
def clean_df(df: pd.DataFrame) -> pd.DataFrame:
    df.columns = (
        df.columns.str.lower()
        .str.replace(r"[^\w]+", "_", regex=True)
        .str.strip("_")
    )
    return df

# DQ check (All NaN rows)
def remove_all_nans(df: pd.DataFrame, name: str) -> pd.DataFrame:
    nan_count = df.isna().all(axis=1).sum()
    if nan_count > 0:
        print(f"Found {nan_count} all-NaN rows in {name}. Removing.")
        df.dropna(how="all", inplace=True)
    return df
  
# -- Extract + Transform ---
def extract_police_data(**ctx):

    # Get latest month from API
    r = requests.get(API_DATES)
    r.raise_for_status()
    latest_month = r.json()[0]["date"]      
    #latest_month = "2025-08" #  (replace latest month with "2025-08" do backfill the data for Aug 2025 and rerun the DAG)
    print(f"Latest month: {latest_month}")

    # ClickHouse connection
    client = get_client(
        host="clickhouse-server",
        port=8123,
        user=os.getenv("CLICKHOUSE_USER"),
        password=os.getenv("CLICKHOUSE_PASSWORD"),
    )

    # Skip if already ingested
    crime_exists = client.query(f"SELECT 1 FROM bronze.bronze_crime_raw WHERE data_month='{latest_month}' LIMIT 1")
    stop_exists = client.query(f"SELECT 1 FROM bronze.bronze_stopsearch_raw WHERE data_month='{latest_month}' LIMIT 1")

    if crime_exists.result_rows and stop_exists.result_rows:
        raise AirflowSkipException("Both datasets already loaded")

    # Download ZIP
    url = ARCHIVE_URL.format(month=latest_month)
    print(f"Downloading: {url}")
    resp = requests.get(url, stream=True)
    resp.raise_for_status()
    z = zipfile.ZipFile(io.BytesIO(resp.content))

    # Find the relevant files
    files = [
        f
        for f in z.namelist()
        if FORCE in f.lower()
        and latest_month in f.lower()   #  only current month 
        and ("street" in f.lower() or "stop-and-search" in f.lower())
    ]

    if not files:
        raise ValueError(f"No matching files found in archive for force '{FORCE}'")

    crime_file = next(f for f in files if "street" in f.lower())
    stop_file = next(f for f in files if "stop-and-search" in f.lower())

    print(f"Using crime file: {crime_file}")
    print(f"Using stop_search file: {stop_file}")

    # Load + clean
    crime_df = clean_df(pd.read_csv(z.open(crime_file)))
    stop_df = clean_df(pd.read_csv(z.open(stop_file)))

    # Drop all Nan Rows
    crime_df = remove_all_nans(crime_df, "crime_df")
    stop_df = remove_all_nans(stop_df, "stop_df")

    crime_df["data_month"] = latest_month
    stop_df["data_month"] = latest_month

    # Fix types
    crime_df = fix_crime_types(crime_df)
    stop_df = fix_stopsearch_types(stop_df)

    print(f"Crime data prepared ({len(crime_df)} rows)")
    print(f"Stop-search data prepared ({len(stop_df)} rows)")

    # Ensure temp directory exists
    os.makedirs(TMP_DIR, exist_ok=True)

    crime_path = os.path.join(TMP_DIR, f"crime_{latest_month}.csv")
    stop_path = os.path.join(TMP_DIR, f"stop_{latest_month}.csv")

    crime_df.to_csv(crime_path, index=False)
    stop_df.to_csv(stop_path, index=False)

    print(f"Crime CSV saved to: {crime_path}")
    print(f"Stop-search CSV saved to: {stop_path}")

    # Push only paths + month via XCom (small payload)
    ti = ctx["ti"]
    ti.xcom_push("month", latest_month)
    ti.xcom_push("crime_path", crime_path)
    ti.xcom_push("stop_path", stop_path)


# -- Load to ClickHouse ---
def load_to_clickhouse(**ctx):
    ti = ctx["ti"]

    latest_month = ti.xcom_pull(task_ids="extract_transform_task", key="month")
    crime_path = ti.xcom_pull(task_ids="extract_transform_task", key="crime_path")
    stop_path = ti.xcom_pull(task_ids="extract_transform_task", key="stop_path")

    if not latest_month or not crime_path or not stop_path:
        raise ValueError("Missing month or file paths from XCom – extract step failed?")

    if not (os.path.exists(crime_path) and os.path.exists(stop_path)):
        raise FileNotFoundError(
            f"Expected CSV files not found: {crime_path}, {stop_path}"
        )
    
    print(f"Loading data for month: {latest_month}")

    # Read back into DataFrames
    crime_df = pd.read_csv(crime_path)
    stop_df = pd.read_csv(stop_path)

    print(f"Crime rows to insert: {len(crime_df)}")
    print(f"Stop-search rows to insert: {len(stop_df)}")

    # Fix types (Ensure that the types are correct!)
    crime_df = fix_crime_types(crime_df)
    stop_df = fix_stopsearch_types(stop_df)

    #print("Columns in crime_df:", crime_df.columns.tolist()) for debugging
    #print("Columns in stop_df:", stop_df.columns.tolist())

    client = get_client(
        host="clickhouse-server",
        port=8123,
        user=os.getenv("CLICKHOUSE_USER"),
        password=os.getenv("CLICKHOUSE_PASSWORD"),
    )

    # Double-check idempotency before load
    crime_exists = client.query(f"SELECT 1 FROM bronze.bronze_crime_raw WHERE data_month='{latest_month}' LIMIT 1")
    stop_exists = client.query(f"SELECT 1 FROM bronze.bronze_stopsearch_raw WHERE data_month='{latest_month}' LIMIT 1")

    if crime_exists.result_rows and stop_exists.result_rows:
        raise AirflowSkipException("Both datasets already loaded")


    # Insert into ClickHouse
    if not crime_df.empty:
        client.insert_df("bronze.bronze_crime_raw", crime_df)

    if not stop_df.empty:
        client.insert_df("bronze.bronze_stopsearch_raw", stop_df)

    print("Load complete.")


# -- DAG definition ---
with DAG(
    dag_id="police_data_ingestion",
    start_date=days_ago(1),
    schedule_interval="@monthly",
    catchup=False,
    max_active_runs=1,
    tags=["police", "ETL"],
) as dag:

    extract_task = PythonOperator(
        task_id="extract_transform_task",
        python_callable=extract_police_data,
    )

    load_task = PythonOperator(
        task_id="load_to_clickhouse_task",
        python_callable=load_to_clickhouse,
    )
    run_dbt = BashOperator(
        task_id="run_dbt_models",
        bash_command="cd /opt/airflow/dbt && dbt run && dbt test",
    )

    extract_task >> load_task >> run_dbt
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago
from airflow.hooks.postgres_hook import PostgresHook
import requests, zipfile, io, pandas as pd

# --- Config ---
FORCE = "cambridgeshire"
API_DATES = "https://data.police.uk/api/crimes-street-dates"
ARCHIVE_URL = "https://data.police.uk/data/archive/{month}.zip"
POSTGRES_CONN_ID = "project_db"

# --- Task function ---
def fetch_and_load_police_data(**ctx):
    """Fetch the latest month from API, download ZIP, extract Cambridgeshire data, and load to Postgres."""
    
    # Get latest (updated) available month of data from souce
    r = requests.get(API_DATES)
    r.raise_for_status()
    latest_month = r.json()[0]["date"]
    print(f"Latest month: {latest_month}")

    # Connect to Postgres
    pg = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID)
    engine = pg.get_sqlalchemy_engine()

    # Check if month already ingested
    check_query = """
        SELECT 1 FROM crimes WHERE data_month = %s LIMIT 1;
    """
    try:
        exists = pg.get_first(check_query, parameters=(latest_month,))
        if exists:
            print(f"Month {latest_month} already in database. Skipping.")
            return
    except Exception:
        print("Table might not exist yet — proceeding with first load.")

    # Download ZIP for that month
    url = ARCHIVE_URL.format(month=latest_month)
    print(f"Downloading {url}")
    resp = requests.get(url, stream=True)
    z = zipfile.ZipFile(io.BytesIO(resp.content))

    # Find Cambridgeshire CSVs
    files = [f for f in z.namelist() if FORCE in f.lower() and ("street" in f.lower() or "stop-and-search" in f.lower())]
    print("Found files:", files)

    # Step 5: Load CSVs into Postgres
    for f in files:
        df = pd.read_csv(z.open(f))
        df.columns = (
            df.columns.str.strip()
            .str.lower()
            .str.replace(r"[^\w]+", "_", regex=True)
            .str.strip("_")
        )
        df["data_month"] = latest_month
        table = "crimes" if "street" in f.lower() else "stop_search"
        print(f"Loading {table}: {len(df)} rows")

        # Create table if missing
        cols_sql = ", ".join([f'"{c}" TEXT' for c in df.columns])
        pg.run(f"CREATE TABLE IF NOT EXISTS {table} ({cols_sql});")

        # Remove duplicates for same month
        pg.run(f"DELETE FROM {table} WHERE data_month = %s;", parameters=(latest_month,))

        # Insert data
        df.to_sql(table, engine, if_exists="append", index=False)

    print("✅ Done loading data for", latest_month)


# --- Airflow DAG definition ---
with DAG(
    dag_id="police_data_ingestion",
    start_date=days_ago(1),
    schedule_interval="@monthly",
    catchup=False,
    max_active_runs=1,
    tags=["police", "ETL"],
) as dag:

    fetch_and_load = PythonOperator(
        task_id="fetch_and_load_police_data",
        python_callable=fetch_and_load_police_data,
        provide_context=True,
    )

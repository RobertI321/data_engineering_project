#!/bin/bash

# Wait for ClickHouse to be available
echo "Waiting for ClickHouse..."
until clickhouse-client --query="SELECT 1" >/dev/null 2>&1; do
  sleep 1
done

echo "ClickHouse is ready. Running initialization SQL..."

# Create Bronze tables
clickhouse-client --multiquery < /sql/01_create_bronze_tables.sql

# Create Iceberg catalog database
clickhouse-client --multiquery < /sql/02_make_iceberg_table_queriable.sql

echo "Initialization complete. (created Bronze tables and Iceberg catalog database.)"
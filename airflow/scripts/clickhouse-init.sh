#!/bin/bash

set -e

echo "Waiting for ClickHouse to be ready..."

# Wait for ClickHouse to respond (with longer timeout)
max_attempts=60
attempt=0
until [ $attempt -ge $max_attempts ]; do
  if clickhouse-client --query="SELECT 1" >/dev/null 2>&1; then
    echo "ClickHouse is ready!"
    break
  fi
  attempt=$((attempt + 1))
  echo "Waiting... (attempt $attempt/$max_attempts)"
  sleep 1
done

if [ $attempt -ge $max_attempts ]; then
  echo "ERROR: ClickHouse failed to start after $max_attempts attempts"
  exit 1
fi

echo "Running initialization SQL files..."

# Run initialization scripts
if [ -f "/sql/01_create_bronze_tables.sql" ]; then
  echo "Creating bronze tables..."
  clickhouse-client --multiquery < /sql/01_create_bronze_tables.sql
else
  echo "WARNING: /sql/01_create_bronze_tables.sql not found"
fi

if [ -f "/sql/02_make_iceberg_table_queriable.sql" ]; then
  echo "Setting up Iceberg catalog..."
  clickhouse-client --multiquery < /sql/02_make_iceberg_table_queriable.sql
else
  echo "WARNING: /sql/02_make_iceberg_table_queriable.sql not found"
fi

echo "ClickHouse initialization complete!"
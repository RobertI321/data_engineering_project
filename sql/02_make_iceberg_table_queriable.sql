SET allow_experimental_database_iceberg = 1;
SET allow_experimental_database_unity_catalog = 1;
SET allow_experimental_database_glue_catalog = 1;
SET allow_experimental_database_hms_catalog = 1;

CREATE DATABASE IF NOT EXISTS iceberg
ENGINE = DataLakeCatalog('http://iceberg_rest:8181')
SETTINGS
    catalog_type = 'rest',
    warehouse = 'iceberg-bucket',
    storage_endpoint = 'http://minio:9000',
    aws_access_key_id = '${MINIO_ROOT_USER}',
    aws_secret_access_key = '${MINIO_ROOT_PASSWORD}',
    region = 'us-east-1';
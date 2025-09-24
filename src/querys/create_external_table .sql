CREATE OR REPLACE EXTERNAL TABLE sauter-university-472416.ons_bronze.external_table
OPTIONS (
  uris = ['gs://bucket-sauter-university/basin_data/*.parquet'],
  format = 'PARQUET'
);
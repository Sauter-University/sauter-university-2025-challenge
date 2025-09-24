CREATE OR REPLACE TABLE sauter-university-472416.ons_bronze.ena_basin_bronze AS
SELECT
  nom_bacia,
  ena_data,
  ena_bruta_bacia_mwmed,
  ena_bruta_bacia_percentualmlt,
  ena_armazenavel_bacia_mwmed,
  ena_armazenavel_bacia_percentualmlt,
  CURRENT_TIMESTAMP() AS data_carga_bronze
FROM
  sauter-university-472416.ons_bronze.external_table

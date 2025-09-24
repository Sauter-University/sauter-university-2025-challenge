CREATE OR REPLACE TABLE `sauter-university-472416.ons_silver.ena_basin_silver` AS
WITH
  dados_tipados AS (
    SELECT
      TRIM(UPPER(nom_bacia)) AS nom_bacia,
      SAFE_CAST(ena_data AS DATE) AS ena_data,
      SAFE_CAST(ena_bruta_bacia_mwmed AS NUMERIC) AS ena_bruta_bacia_mwmed,
      SAFE_CAST(ena_bruta_bacia_percentualmlt AS NUMERIC) AS ena_bruta_bacia_percentualmlt,
      SAFE_CAST(ena_armazenavel_bacia_mwmed AS NUMERIC) AS ena_armazenavel_bacia_mwmed,
      SAFE_CAST(ena_armazenavel_bacia_percentualmlt AS NUMERIC) AS ena_armazenavel_bacia_percentualmlt,
      data_carga_bronze
    FROM
      `sauter-university-472416.ons_bronze.ena_basin_bronze`
  ),
  dados_desduplicados AS (
    SELECT
      nom_bacia,
      ena_data,
      ena_bruta_bacia_mwmed,
      ena_bruta_bacia_percentualmlt,
      ena_armazenavel_bacia_mwmed,
      ena_armazenavel_bacia_percentualmlt,
      ROW_NUMBER() OVER (
        PARTITION BY nom_bacia, ena_data 
        ORDER BY ena_data, nom_bacia DESC
      ) AS rn
    FROM
      dados_tipados
  )
SELECT
  nom_bacia,
  ena_data,
  COALESCE(ena_bruta_bacia_mwmed, 0) AS ena_bruta_bacia_mwmed,
  COALESCE(ena_bruta_bacia_percentualmlt, 0) AS ena_bruta_bacia_percentualmlt,
  COALESCE(ena_armazenavel_bacia_mwmed, 0) AS ena_armazenavel_bacia_mwmed,
  COALESCE(ena_armazenavel_bacia_percentualmlt, 0) AS ena_armazenavel_bacia_percentualmlt
FROM
  dados_desduplicados
WHERE
  rn = 1
  AND ena_data IS NOT NULL

ORDER BY
  ena_data, nom_bacia;
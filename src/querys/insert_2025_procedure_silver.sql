CREATE OR REPLACE PROCEDURE `sauter-university-472416.ons_silver.proc_inserir_dados_2025`(p_data DATE)
OPTIONS(strict_mode=false)
BEGIN
  INSERT INTO `sauter-university-472416.ons_dataset.ena_bacia_silver`
  SELECT DISTINCT
    TRIM(UPPER(nom_bacia)) AS nom_bacia,
    SAFE_CAST(ena_data AS DATE) AS ena_data,
    COALESCE(SAFE_CAST(ena_bruta_bacia_mwmed AS NUMERIC), 0) AS ena_bruta_bacia_mwmed,
    COALESCE(SAFE_CAST(ena_bruta_bacia_percentualmlt AS NUMERIC), 0) AS ena_bruta_bacia_percentualmlt,
    COALESCE(SAFE_CAST(ena_armazenavel_bacia_mwmed AS NUMERIC), 0) AS ena_armazenavel_bacia_mwmed,
    COALESCE(SAFE_CAST(ena_armazenavel_bacia_percentualmlt AS NUMERIC), 0) AS ena_armazenavel_bacia_percentualmlt
  FROM
    `sauter-university-472416.ons_dataset.ena_bacia_bronze`
  WHERE SAFE_CAST(ena_data AS DATE) = p_data
    AND SAFE_CAST(ena_data AS DATE) NOT IN (
      SELECT DISTINCT ena_data
      FROM `sauter-university-472416.ons_dataset.ena_bacia_silver`
    );
END;

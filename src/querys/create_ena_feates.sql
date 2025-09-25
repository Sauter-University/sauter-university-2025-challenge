CREATE OR REPLACE TABLE `sauter-university-472416.ons_gold.ena_features_gold` AS
WITH silver_data AS (
  SELECT
    nom_bacia AS Nome_Bacia,
    ena_data AS Data_Referencia,
    ena_armazenavel_bacia_mwmed AS ena_armazenavel
  FROM
    `sauter-university-472416.ons_silver.ena_basin_silver`
),

-- Passo 1: Calcular features que não dependem de outras linhas (seno/cosseno)
features_sazonais AS (
  SELECT
    *,
    EXTRACT(DAYOFYEAR FROM Data_Referencia) AS day_of_year
  FROM
    silver_data
)

-- Passo 2: Usar Funções de Janela para calcular lags e médias móveis
-- A PARTITION BY Nome_Bacia garante que os cálculos não "pulem" de uma bacia para outra.
SELECT
  Nome_Bacia,
  Data_Referencia,
  ena_armazenavel,

  -- Features Sazonais (usamos ACOS(-1) para obter o valor de PI)
  SIN(2 * ACOS(-1) * 1 * day_of_year / 365.25) AS sin_1,
  COS(2 * ACOS(-1) * 1 * day_of_year / 365.25) AS cos_1,
  SIN(2 * ACOS(-1) * 2 * day_of_year / 365.25) AS sin_2,
  COS(2 * ACOS(-1) * 2 * day_of_year / 365.25) AS cos_2,
  SIN(2 * ACOS(-1) * 3 * day_of_year / 365.25) AS sin_3,
  COS(2 * ACOS(-1) * 3 * day_of_year / 365.25) AS cos_3,
  SIN(2 * ACOS(-1) * 4 * day_of_year / 365.25) AS sin_4,
  COS(2 * ACOS(-1) * 4 * day_of_year / 365.25) AS cos_4,

  -- Features de Lag
  LAG(ena_armazenavel, 7) OVER (PARTITION BY Nome_Bacia ORDER BY Data_Referencia) AS lag_7,
  LAG(ena_armazenavel, 14) OVER (PARTITION BY Nome_Bacia ORDER BY Data_Referencia) AS lag_14,
  LAG(ena_armazenavel, 30) OVER (PARTITION BY Nome_Bacia ORDER BY Data_Referencia) AS lag_30,
  LAG(ena_armazenavel, 60) OVER (PARTITION BY Nome_Bacia ORDER BY Data_Referencia) AS lag_60,

  -- Features de Média Móvel (rolling mean)
  AVG(ena_armazenavel) OVER (PARTITION BY Nome_Bacia ORDER BY Data_Referencia ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_mean_7,
  AVG(ena_armazenavel) OVER (PARTITION BY Nome_Bacia ORDER BY Data_Referencia ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS rolling_mean_30

FROM
  features_sazonais
ORDER BY
  Nome_Bacia,
  Data_Referencia;
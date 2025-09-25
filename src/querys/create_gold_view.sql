CREATE OR REPLACE VIEW `sauter-university-472416.ons_gold.vw_previsao_vs_real`
OPTIONS(
  description="Visão que compara a previsão mais recente do modelo com os valores reais, calculando a diferença e o erro percentual."
) AS
WITH
  ultima_previsao AS (
    -- Passo 1: Encontrar o timestamp exato da última vez que o modelo rodou e salvou os dados.
    SELECT
      MAX(data_previsao) AS max_data_previsao
    FROM
      `sauter-university-472416.ons_gold.previsoes_ena`
  ),
  previsoes_recentes AS (
    -- Passo 2: Usar o timestamp encontrado para filtrar apenas as previsões que pertencem a essa última execução.
    SELECT
      data,
      valor AS valor_previsto
    FROM
      `sauter-university-472416.ons_gold.previsoes_ena`
    WHERE
      data_previsao = (SELECT max_data_previsao FROM ultima_previsao)
  )
-- Passo 3: Juntar (JOIN) as previsões mais recentes com os dados reais da tabela silver.
SELECT
  previsoes.data AS data_referencia,
  previsoes.valor_previsto,
  real.ena_armazenavel_bacia_mwmed AS valor_real,

  -- Passo 4: Calcular as métricas de precisão/erro.
  (real.ena_armazenavel_bacia_mwmed - previsoes.valor_previsto) AS diferenca_erro,
  ABS(real.ena_armazenavel_bacia_mwmed - previsoes.valor_previsto) AS erro_absoluto,
  -- Erro Percentual Absoluto (MAPE simplificado)
  SAFE_DIVIDE(ABS(real.ena_armazenavel_bacia_mwmed - previsoes.valor_previsto), real.ena_armazenavel_bacia_mwmed) * 100 AS percentual_erro_abs

FROM
  previsoes_recentes AS previsoes
-- Usamos LEFT JOIN para garantir que veremos todas as previsões, mesmo as futuras que ainda não têm um valor real.
LEFT JOIN
  `sauter-university-472416.ons_silver.ena_basin_silver` AS real
ON
  previsoes.data = real.ena_data
  -- Importante: Garantir que estamos comparando com a mesma bacia do modelo.
  AND real.nom_bacia = 'PARANAPANEMA'
ORDER BY
  data_referencia DESC;
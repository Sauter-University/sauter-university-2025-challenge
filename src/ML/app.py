import pandas as pd
import numpy as np
import joblib
from tensorflow.keras.models import load_model
from flask import Flask, jsonify, request
from google.cloud import bigquery
import os
from datetime import datetime

# --- 1. CONFIGURAÇÃO INICIAL ---
project_id = 'sauter-university-472416'
client = bigquery.Client(project=project_id)

print("Carregando o modelo e o scaler...")
model = load_model('modelo_ena_lstm.keras')
scaler = joblib.load('scaler_ena.pkl')
print("Modelo e scaler carregados com sucesso.")

# --- Constante com a ordem exata das colunas ---
COLUNAS_DO_TREINO = [
    'ena_armazenavel', 'sin_1', 'cos_1', 'sin_2', 'cos_2', 'sin_3', 'cos_3', 'sin_4', 'cos_4',
    'lag_7', 'lag_14', 'lag_30', 'lag_60', 'rolling_mean_7', 'rolling_mean_30'
]

# --- 2. FUNÇÕES DE SUPORTE (RESTAURADAS) ---

def buscar_dados_recentes(nome_bacia, dias_necessarios, data_base=None):
    """Busca os dados BRUTOS da tabela Silver. Pede mais dias para calcular lags."""
    print(f"Buscando dados brutos para a bacia {nome_bacia}...")
    
    query_filtro_data = ""
    if data_base:
        query_filtro_data = f"AND ena_data <= '{data_base}'"

    query = f"""
        SELECT
            ena_data,
            ena_armazenavel_bacia_mwmed
        FROM
            `sauter-university-472416.ons_silver.ena_basin_silver`
        WHERE
            nom_bacia = '{nome_bacia}'
            {query_filtro_data}
        ORDER BY
            ena_data DESC
        LIMIT {dias_necessarios}
    """
    df = client.query(query).to_dataframe()
    df['ena_data'] = pd.to_datetime(df['ena_data'])
    df.set_index('ena_data', inplace=True)
    df.sort_index(inplace=True)
    df = df.rename(columns={'ena_armazenavel_bacia_mwmed': 'ena_armazenavel'})
    df.ffill(inplace=True)
    return df

def criar_features(df):
    """Cria o mesmo conjunto de features usado no treinamento."""
    df_features = df.copy()
    day_of_year = df_features.index.dayofyear
    for k in range(1, 5):
        df_features[f'sin_{k}'] = np.sin(2 * np.pi * k * day_of_year / 365.25)
        df_features[f'cos_{k}'] = np.cos(2 * np.pi * k * day_of_year / 365.25)
    for lag in [7, 14, 30, 60]:
        df_features[f'lag_{lag}'] = df_features['ena_armazenavel'].shift(lag)
    for window in [7, 30]:
        df_features[f'rolling_mean_{window}'] = df_features['ena_armazenavel'].rolling(window=window).mean()
    df_features.dropna(inplace=True)
    return df_features

# --- 3. LÓGICA DE PREVISÃO ATUALIZADA ---
def gerar_previsao_futura(horizonte_previsao=180, window_size=180, data_base=None):
    # Pedir dados brutos suficientes para criar a primeira janela de features
    # (window_size + 60 dias para o maior lag)
    dados_historicos = buscar_dados_recentes('TOCANTINS', dias_necessarios=window_size + 60, data_base=data_base)
    
    # Criar features a partir dos dados brutos
    df_com_features = criar_features(dados_historicos)

    if len(df_com_features) < window_size:
        raise ValueError(f"Não foram encontrados dados suficientes (após criar features) antes de {data_base} para a janela de {window_size} dias.")

    # Pegar a última janela de dados (já com features e na ordem correta)
    input_df_recursivo = df_com_features.tail(window_size)[COLUNAS_DO_TREINO]
    
    # Normalizar a janela inicial
    input_scaled_recursivo = scaler.transform(input_df_recursivo)
    
    previsoes_finais = []

    for i in range(horizonte_previsao):
        input_para_prever = input_scaled_recursivo.reshape((1, window_size, input_df_recursivo.shape[1]))
        proxima_previsao_scaled = model.predict(input_para_prever, verbose=0)
        
        # Desnormalizar a previsão para obter o valor real
        dummy_array = np.zeros((1, input_df_recursivo.shape[1]))
        dummy_array[0, 0] = proxima_previsao_scaled[0, 0]
        proxima_previsao_descaled = scaler.inverse_transform(dummy_array)[0, 0]
        previsoes_finais.append(proxima_previsao_descaled)
        
        # Criar as features para o próximo dia usando o valor real previsto
        nova_data = input_df_recursivo.index[-1] + pd.Timedelta(days=1)
        temp_series = pd.concat([input_df_recursivo['ena_armazenavel'], pd.Series([proxima_previsao_descaled], index=[nova_data])])
        
        novo_dia_features = pd.DataFrame(index=[nova_data])
        novo_dia_features['ena_armazenavel'] = proxima_previsao_descaled
        day_of_year = novo_dia_features.index.dayofyear
        for k in range(1, 5):
            novo_dia_features[f'sin_{k}'] = np.sin(2 * np.pi * k * day_of_year / 365.25)
            novo_dia_features[f'cos_{k}'] = np.cos(2 * np.pi * k * day_of_year / 365.25)
        for lag in [7, 14, 30, 60]:
            novo_dia_features[f'lag_{lag}'] = temp_series.shift(lag).iloc[-1]
        for window in [7, 30]:
            novo_dia_features[f'rolling_mean_{window}'] = temp_series.rolling(window=window).mean().iloc[-1]

        # Normalizar a nova linha (garantindo a ordem das colunas)
        novo_dia_scaled = scaler.transform(novo_dia_features[COLUNAS_DO_TREINO])

        # Atualizar a janela para a próxima iteração
        input_scaled_recursivo = np.append(input_scaled_recursivo[1:], novo_dia_scaled, axis=0)
        input_df_recursivo = pd.concat([input_df_recursivo.iloc[1:], novo_dia_features[COLUNAS_DO_TREINO]])

    # Criar o DataFrame de resultado final
    datas_previsao = pd.to_datetime(pd.date_range(start=df_com_features.index[-1] + pd.Timedelta(days=1), periods=horizonte_previsao))
    df_resultado = pd.DataFrame({'data': datas_previsao.strftime('%Y-%m-%d'), 'valor': previsoes_finais})
    
    return df_resultado

# --- O resto do código (salvar no BQ e o endpoint Flask) continua o mesmo ---

def salvar_previsoes_no_bigquery(df_previsoes):
    df_para_salvar = df_previsoes.copy()
    df_para_salvar['data_previsao'] = datetime.utcnow()
    df_para_salvar['data'] = pd.to_datetime(df_para_salvar['data'])
    table_id = "sauter-university-472416.ons_gold.previsoes_ena"
    job_config = bigquery.LoadJobConfig(write_disposition="WRITE_APPEND",)
    try:
        print(f"Salvando {len(df_para_salvar)} previsões na tabela {table_id}...")
        job = client.load_table_from_dataframe(df_para_salvar, table_id, job_config=job_config)
        job.result()
        print("Previsões salvas com sucesso no BigQuery.")
    except Exception as e:
        print(f"Erro ao salvar dados no BigQuery: {e}")

app = Flask(__name__)

@app.route('/prever', methods=['GET'])
def prever():
    try:
        horizonte = request.args.get('horizonte', default=180, type=int)
        data_base = request.args.get('data_base', default=None, type=str)

        print(f"Requisição recebida. Gerando previsão para {horizonte} dias...")
        df_previsao = gerar_previsao_futura(horizonte_previsao=horizonte, window_size=180, data_base=data_base)

        salvar_previsoes_no_bigquery(df_previsao)
        resultado = df_previsao.to_dict(orient='records')
        
        print("Previsão gerada e salva com sucesso.")
        return jsonify(resultado)

    except Exception as e:
        print(f"Erro durante a previsão: {e}")
        return jsonify({"erro": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
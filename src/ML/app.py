import pandas as pd
import numpy as np
import joblib
from tensorflow.keras.models import load_model
from flask import Flask, jsonify, request
from google.cloud import bigquery
import os
from datetime import datetime

# --- 1. CONFIGURAÇÃO INICIAL (sem alterações) ---
project_id = 'sauter-university-472416'
client = bigquery.Client(project=project_id)

print("Carregando o modelo e o scaler...")
model = load_model('modelo_ena_lstm.keras')
scaler = joblib.load('scaler_ena.pkl')
print("Modelo e scaler carregados com sucesso.")

# --- 2. ### FUNÇÃO ALTERADA ### ---
def buscar_dados_com_features(nome_bacia, dias_necessarios):
    """Busca os dados já com features da tabela GOLD do BigQuery."""
    print(f"Buscando os últimos {dias_necessarios} dias de dados com features para a bacia {nome_bacia}...")
    
    # IMPORTANTE: A ordem das colunas no SELECT deve ser EXATAMENTE a mesma
    # que o seu scaler espera. Verifique a ordem no seu notebook de treinamento.
    query = f"""
        SELECT
            ena_armazenavel,
            sin_1, cos_1, sin_2, cos_2, sin_3, cos_3, sin_4, cos_4,
            lag_7, lag_14, lag_30, lag_60,
            rolling_mean_7, rolling_mean_30,
            Data_Referencia -- A data ainda é útil para o índice
        FROM
            `sauter-university-472416.ons_gold.ena_features_gold`
        WHERE
            Nome_Bacia = '{nome_bacia}'
            -- Garante que não pegamos linhas com features nulas
            AND lag_60 IS NOT NULL 
        ORDER BY
            Data_Referencia DESC
        LIMIT {dias_necessarios}
    """
    df = client.query(query).to_dataframe()
    
    # A query já vem ordenada do mais novo para o mais antigo (DESC),
    # então precisamos inverter para o modelo (do mais antigo para o mais novo).
    df = df.sort_values(by='Data_Referencia', ascending=True)
    df.set_index('Data_Referencia', inplace=True)
    
    return df

# --- 3. ### FUNÇÃO REMOVIDA ### ---
# A função criar_features(df) não é mais necessária!

# --- 4. LÓGICA DE PREVISÃO (com pequenas alterações) ---
def gerar_previsao_futura(horizonte_previsao=180, window_size=180):
    # Não precisamos mais de um buffer (como +60), pegamos exatamente o que a janela precisa.
    df_com_features = buscar_dados_com_features('PARANAPANEMA', dias_necessarios=window_size)
    
    # Pegar a última janela de dados (o DataFrame já está pronto)
    input_atual_df = df_com_features
    
    # O resto da função continua praticamente igual...
    input_atual_scaled = scaler.transform(input_atual_df)
    
    lista_previsoes_scaled = []

    for i in range(horizonte_previsao):
        input_para_prever = input_atual_scaled.reshape((1, window_size, input_atual_df.shape[1]))
        proxima_previsao_scaled = model.predict(input_para_prever, verbose=0)
        lista_previsoes_scaled.append(proxima_previsao_scaled[0, 0])
        
        # A lógica para criar a "próxima linha" para a previsão recursiva ainda é necessária
        # porque precisamos prever passo a passo.
        nova_previsao_valor = proxima_previsao_scaled[0, 0]
        nova_data = input_atual_df.index[-1] + pd.Timedelta(days=1)
        
        novo_dia_features = pd.DataFrame(index=[nova_data])
        novo_dia_features['ena_armazenavel'] = 0 
        
        day_of_year = novo_dia_features.index.dayofyear
        for k in range(1, 5):
            novo_dia_features[f'sin_{k}'] = np.sin(2 * np.pi * k * day_of_year / 365.25)
            novo_dia_features[f'cos_{k}'] = np.cos(2 * np.pi * k * day_of_year / 365.25)
        
        temp_series = pd.concat([input_atual_df['ena_armazenavel'], pd.Series([0], index=[nova_data])])
        for lag in [7, 14, 30, 60]:
            novo_dia_features[f'lag_{lag}'] = temp_series.shift(lag).iloc[-1]
        for window in [7, 30]:
            novo_dia_features[f'rolling_mean_{window}'] = temp_series.rolling(window=window).mean().iloc[-1]

        novo_dia_features['ena_armazenavel'] = nova_previsao_valor
        novo_dia_scaled = scaler.transform(novo_dia_features[input_atual_df.columns])
        
        input_atual_scaled = np.append(input_atual_scaled[1:], novo_dia_scaled, axis=0)
        input_atual_df = pd.concat([input_atual_df.iloc[1:], pd.DataFrame(scaler.inverse_transform(novo_dia_scaled), index=[nova_data], columns=input_atual_df.columns)])

    previsoes_array_scaled = np.array(lista_previsoes_scaled).reshape(-1, 1)
    dummy_array_pred = np.zeros((len(previsoes_array_scaled), input_atual_df.shape[1]))
    dummy_array_pred[:, 0] = previsoes_array_scaled.flatten()
    previsoes_finais = scaler.inverse_transform(dummy_array_pred)[:, 0]
    
    datas_previsao = pd.to_datetime(pd.date_range(start=df_com_features.index[-1] + pd.Timedelta(days=1), periods=horizonte_previsao))
    df_resultado = pd.DataFrame({'data': datas_previsao.strftime('%Y-%m-%d'), 'valor': previsoes_finais})
    
    return df_resultado


# --- 4. ### NOVA FUNÇÃO ### PARA SALVAR NO BIGQUERY ---
def salvar_previsoes_no_bigquery(df_previsoes):
    """Carrega o DataFrame de previsões em uma tabela do BigQuery."""
    
    # Adiciona a coluna com o timestamp de quando a previsão foi gerada
    df_para_salvar = df_previsoes.copy()
    df_para_salvar['data_previsao'] = datetime.utcnow()
    
    # Garante que os tipos de dados estão corretos para o BQ
    df_para_salvar['data'] = pd.to_datetime(df_para_salvar['data'])
    
    table_id = "sauter-university-472416.ons_gold.previsoes_ena"
    
    # Configura o job para carregar os dados. APPEND adiciona os dados na tabela.
    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_APPEND",
    )
    
    try:
        print(f"Salvando {len(df_para_salvar)} previsões na tabela {table_id}...")
        job = client.load_table_from_dataframe(
            df_para_salvar, table_id, job_config=job_config
        )
        job.result()  # Espera o job ser concluído
        print("Previsões salvas com sucesso no BigQuery.")
    except Exception as e:
        print(f"Erro ao salvar dados no BigQuery: {e}")
        # Decide o que fazer em caso de erro. Pode ser só logar ou levantar uma exceção.

# --- 5. ### ALTERADO ### ENDPOINT FLASK ---
app = Flask(__name__)

@app.route('/prever', methods=['GET'])
def prever():
    try:
        horizonte = request.args.get('horizonte', default=180, type=int)
        
        print(f"Requisição recebida. Gerando previsão para {horizonte} dias...")
        df_previsao = gerar_previsao_futura(horizonte_previsao=horizonte)
        
        # ### ALTERAÇÃO AQUI ###: Chama a função para salvar antes de retornar
        salvar_previsoes_no_bigquery(df_previsao)
        
        resultado = df_previsao.to_dict(orient='records')
        
        print("Previsão gerada e salva com sucesso.")
        return jsonify(resultado)

    except Exception as e:
        print(f"Erro durante a previsão: {e}")
        return jsonify({"erro": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
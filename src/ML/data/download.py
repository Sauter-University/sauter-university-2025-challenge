import os
import requests
import pandas as pd
from datetime import datetime

# --- Configurações ---
# URL base com um espaço reservado {} para o ano
BASE_URL = "https://ons-aws-prod-opendata.s3.amazonaws.com/dataset/ena_bacia_di/ENA_DIARIO_BACIAS_{}.csv"

# Anos que você quer baixar
ANO_INICIO = 2000
# O script irá até o ano atual para não tentar baixar arquivos de anos futuros que não existem
ANO_FIM = datetime.now().year 

# Pasta onde os arquivos baixados serão salvos
PASTA_OUTPUT = "dados_ons_baixados"

# Nome do arquivo final consolidado
ARQUIVO_FINAL = f"ENA_DIARIO_BACIAS_CONSOLIDADO_{ANO_INICIO}-{ANO_FIM}.csv"


def baixar_arquivos():
    """
    Função para baixar os arquivos CSV para cada ano no intervalo definido.
    """
    print("--- INICIANDO DOWNLOAD DOS ARQUIVOS ---")
    
    # Cria a pasta de output se ela não existir
    if not os.path.exists(PASTA_OUTPUT):
        os.makedirs(PASTA_OUTPUT)
        print(f"Pasta '{PASTA_OUTPUT}' criada com sucesso.")

    # Loop através dos anos
    for ano in range(ANO_INICIO, ANO_FIM + 1):
        url_completa = BASE_URL.format(ano)
        nome_arquivo_local = os.path.join(PASTA_OUTPUT, f"ENA_DIARIO_BACIAS_{ano}.csv")

        print(f"Tentando baixar dados para o ano {ano}...")
        
        try:
            # Faz a requisição para a URL
            response = requests.get(url_completa, timeout=30)
            
            # Verifica se o download foi bem-sucedido (código 200)
            if response.status_code == 200:
                # Salva o conteúdo do arquivo
                with open(nome_arquivo_local, 'wb') as f:
                    f.write(response.content)
                print(f"✅ Sucesso! Arquivo para {ano} salvo em '{nome_arquivo_local}'")
            else:
                # Se o arquivo não for encontrado (404) ou o acesso for negado (403), avisa e continua
                print(f"⚠️  Aviso: Não foi possível baixar o arquivo para {ano}. Status: {response.status_code}")

        except requests.exceptions.RequestException as e:
            print(f"❌ Erro de conexão ao tentar baixar para o ano {ano}: {e}")

    print("\n--- DOWNLOAD DOS ARQUIVOS CONCLUÍDO ---\n")


def juntar_arquivos():
    """
    Função para ler todos os arquivos baixados e juntá-los em um único CSV.
    """
    print("--- INICIANDO CONSOLIDAÇÃO DOS ARQUIVOS ---")
    
    lista_de_dataframes = []
    
    # Lista os arquivos na pasta de downloads
    arquivos_baixados = sorted([f for f in os.listdir(PASTA_OUTPUT) if f.endswith('.csv')])
    
    if not arquivos_baixados:
        print("Nenhum arquivo CSV encontrado na pasta para consolidar.")
        return

    # Loop para ler cada arquivo CSV e adicioná-lo a uma lista
    for nome_arquivo in arquivos_baixados:
        caminho_completo = os.path.join(PASTA_OUTPUT, nome_arquivo)
        print(f"Lendo o arquivo: {nome_arquivo}...")
        try:
            # ONS costuma usar ';' como separador. Se der erro, pode ser ','
            df = pd.read_csv(caminho_completo, sep=';', encoding='latin-1')
            lista_de_dataframes.append(df)
        except Exception as e:
            print(f"❌ Erro ao ler o arquivo {nome_arquivo}: {e}")

    if not lista_de_dataframes:
        print("Não foi possível ler nenhum DataFrame para consolidar.")
        return

    # Concatena todos os dataframes da lista em um só
    print("\nJuntando todos os dados...")
    df_final = pd.concat(lista_de_dataframes, ignore_index=True)
    
    # Salva o dataframe final em um novo arquivo CSV
    # index=False para não salvar o índice do pandas no arquivo
    df_final.to_csv(ARQUIVO_FINAL, sep=';', index=False, encoding='utf-8-sig')
    
    print(f"\n✅ SUCESSO! Todos os dados foram consolidados no arquivo '{ARQUIVO_FINAL}'")


# --- Execução Principal ---
if __name__ == "__main__":
    baixar_arquivos()
    juntar_arquivos()
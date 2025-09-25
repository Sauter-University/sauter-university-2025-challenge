# Usar uma imagem base oficial do Python
FROM python:3.9-slim

# Definir o diretório de trabalho dentro do contêiner
WORKDIR /app

# Copiar o arquivo de requisitos para o contêiner
COPY requirements.txt .

# Instalar as bibliotecas Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar todos os arquivos do seu projeto (app.py, .keras, .pkl) para o contêiner
COPY . .

# Comando para iniciar o servidor web quando o contêiner rodar
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
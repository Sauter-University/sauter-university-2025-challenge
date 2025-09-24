# ---- Estágio 1: Builder ----
FROM python:3.11-slim as builder
WORKDIR /usr/src/app
ENV PIP_NO_CACHE_DIR=off PIP_DISABLE_PIP_VERSION_CHECK=on

# Copia o arquivo de dependências
COPY requirements.txt .

# Cria o "wheelhouse" usando o comando padrão e universal do pip
# Esta é a forma mais robusta e compatível de fazer isso.
RUN pip wheel -r requirements.txt --wheel-dir /usr/src/app/wheels


# ---- Estágio 2: Final ----
FROM python:3.11-slim
WORKDIR /usr/src/app
ENV PYTHONDONTWRITEBYTECODE 1 PYTHONUNBUFFERED 1

# Copia os pacotes "wheel" do estágio anterior
COPY --from=builder /usr/src/app/wheels /wheels

# Instala as dependências a partir dos wheels locais, o que é muito mais rápido
RUN pip install --no-index --find-links=/wheels /wheels/*

# Copia o código da sua API para o container
COPY . .

# Expõe a porta e define o comando de execução
EXPOSE 8080
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8080"]
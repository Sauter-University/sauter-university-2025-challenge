# ---- Estágio 1: Builder ----
FROM python:3.11-slim as builder
WORKDIR /usr/src/app
ENV PIP_NO_CACHE_DIR=off PIP_DISABLE_PIP_VERSION_CHECK=on

# Instala o uv para builds rápidos
RUN pip install uv

# Copia o arquivo de dependências (agora está na mesma pasta)
COPY requirements.txt .

# Cria o wheelhouse com uv
RUN uv pip wheel --wheel-dir /usr/src/app/wheels -r requirements.txt


# ---- Estágio 2: Final ----
FROM python:3.11-slim
WORKDIR /usr/src/app
ENV PYTHONDONTWRITEBYTECODE 1 PYTHONUNBUFFERED 1

# Instala o uv
RUN pip install uv

# Copia os wheels e o requirements.txt do estágio anterior
COPY --from=builder /usr/src/app/wheels /wheels
COPY --from=builder /usr/src/app/requirements.txt .

# Instala as dependências a partir dos wheels com uv
RUN uv pip install --system --no-cache /wheels/*

# Copia todo o código da pasta atual (src/api) para o container
COPY . .

# Expõe a porta e define o comando de execução
EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
# ---- Estágio 1: Builder ----
FROM python:3.11-slim as builder
WORKDIR /usr/src/app
ENV PIP_NO_CACHE_DIR=off PIP_DISABLE_PIP_VERSION_CHECK=on

# CORREÇÃO: Copia o requirements.txt a partir do caminho correto (api/requirements.txt)
# já que o contexto do build agora é a pasta 'src'.
COPY api/requirements.txt .

# Cria o "wheelhouse" usando o comando padrão e universal do pip
RUN pip wheel -r requirements.txt --wheel-dir /usr/src/app/wheels


# ---- Estágio 2: Final ----
FROM python:3.11-slim
WORKDIR /usr/src/app
ENV PYTHONDONTWRITEBYTECODE 1 PYTHONUNBUFFERED 1

# Copia os pacotes "wheel" do estágio anterior
COPY --from=builder /usr/src/app/wheels /wheels

# Instala as dependências a partir dos wheels locais
RUN pip install --no-index --find-links=/wheels /wheels/*

# Copia todo o código da API para a pasta de trabalho
COPY api/ .

# Expõe a porta e define o comando de execução, apontando para o módulo correto
EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
# src/api/tests/test_main.py

from fastapi.testclient import TestClient
# O import agora é mais explícito, tratando 'src' como o pacote raiz
from src.api.main import app 

# Cria um cliente de teste para a sua API
client = TestClient(app)

def test_read_root():
    """
    Testa se o endpoint principal (/) está funcionando corretamente.
    """
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Welcome to the Reservoir Data API. See /docs for more information."}

def test_docs_redirect():
    """
    Testa se o endpoint /docs (Swagger UI) está acessível.
    """
    response = client.get("/docs")
    assert response.status_code == 200
from fastapi.testclient import TestClient
# Ajuste o import para apontar para o seu app FastAPI
from src.api.main import app 

# Cria um cliente de teste para a sua API
client = TestClient(app)

def test_read_root():
    """
    Testa se o endpoint principal (/) está funcionando corretamente.
    """
    # Faz uma requisição GET para o endpoint "/"
    response = client.get("/")
    
    # Verifica se o status code da resposta é 200 (OK)
    assert response.status_code == 200
    
    # Verifica se o corpo da resposta contém o JSON esperado
    assert response.json() == {"message": "Welcome to the Reservoir Data API. See /docs for more information."}

def test_docs_redirect():
    """
    Testa se o endpoint /docs (Swagger UI) está acessível.
    """
    response = client.get("/docs")
    assert response.status_code == 200
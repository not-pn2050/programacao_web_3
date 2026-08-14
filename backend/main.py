from fastapi import FastAPI

app = FastAPI(title="API do Meu Projeto", version="0.1.0")

@app.get("/")
def raiz():
    return {"mensagem": "API do meu projeto esta no ar!"}

@app.get("/produtos")
def listar_produtos():
    return [{"id": 1, "nome": "Arroz", "Valiade": "20/08/2027","Marca": "Tio Elias", "DataEntrada":"05/07/2026", "DataSaida": "None"}]
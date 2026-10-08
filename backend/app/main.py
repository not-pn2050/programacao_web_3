from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

from .database import Base, engine
from .camisas import controller as camisas_controller
from .camisas.erros import ErroDeCamisa, CamisaNaoEncontrada

Base.metadata.create_all(bind=engine)

app = FastAPI(title="API do Meu Projeto", version="0.1.0") 
app.include_router(camisas_controller.router)

app.add_middleware(
    CORSMiddleware,
    allow_origins_regex=r"gttp://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.exception_handler(ErroDeCamisa)
def traduzir_recusa(request: Request, erro: ErroDeCamisa):
    codigo = 404 if isinstance(erro, CamisaNaoEncontrada) else 409
    return JSONResponse(status_code=codigo, content={"detail": str(erro)})

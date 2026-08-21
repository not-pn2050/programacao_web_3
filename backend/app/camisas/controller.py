from fastapi import APIRouter, HTTPException, status 

from .schemas import CamisaCriar, CamisaPublico, CamisaAtualizar

router = APIRouter(prefix="/camisa", tags=["Camisa"]) 

# Banco de mentira: uma lista em memoria. Vira banco de verdade no encontro 4. 
 
camisas: list[dict] = [{"id": 0, "time":"palmeiras", "temporada":"2023", "cor":"branca", "descricao":"camisa 2 palmeiras branca"},
    {"id": 1, "time":"gremio", "temporada":"2023", "cor":"tradicional", "descricao":"camisa 1 gremio"}
]

@router.get("/", response_model=list[CamisaPublico])
def listar():
    return camisas

@router.post("/", response_model=CamisaPublico, status_code=201) 
def criar(dados: CamisaCriar):     
    novo = {"id": len(camisas) + 1, **dados.model_dump()}     
    camisas.append(novo)     
    return novo

@router.get("/{camisa_id}", response_model=CamisaPublico) 
def buscar(produto_id: int):     
    for c in camisas:         
        if c["id"] == produto_id:             
            return c     
        raise HTTPException(status_code=404, detail="Produto nao encontrado")

@router.patch("/{camisa_id}", response_model=CamisaPublico) 
def atualizar(produto_id: int, dados: CamisaAtualizar):     
    for c in camisas:         
        if c["id"] == produto_id:             
            c.update(dados.model_dump(exclude_unset=True))             
            return c     
        raise HTTPException(status_code=404, detail="Produto nao encontrado")
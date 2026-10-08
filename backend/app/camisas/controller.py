from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..segunraca import get_curent_user
from ..usuarios.models import Usuario
from . import service
from .schemas import CamisaAtualizar, CamisaCriar, CamisaPublico


router = APIRouter(
    prefix="/camisa", 
    tags=["Camisa"],
    dependencies=[Depends(get_curent_user)],
    ) 

# Banco de mentira: uma lista em memoria. Vira banco de verdade no encontro 4. 


@router.get("/", response_model=list[CamisaPublico])
def listar(
    time: str | None,
    cor: str | None,
    temporada: str | None,
    descricao: str | None,
    usuario: Usuario = Depends(get_curent_user),
    db: Session = Depends(get_db)):
    return service.listar(db, usuario,time,cor,temporada,descricao)


@router.post("/", response_model=CamisaPublico, status_code=201) 
def criar(
    dados: CamisaCriar, 
    db: Session = Depends(get_db)
    ):     
    return service.criar(db, dados.model_dump())

@router.get("/{camisa_id}", response_model=CamisaPublico) 
def buscar(
    produto_id: int, 
    db: Session = Depends(get_db)
    ):     
    return service.buscar(db, produto_id)

@router.patch("/{camisa_id}", response_model=CamisaPublico) 
def atualizar(
    produto_id: int,
    dados: CamisaAtualizar,
    db: Session = Depends(get_db),
    ):     
    return service.atualizar(
        db, produto_id, dados.model_dump(exclude_unset=True)
    )

@router.delete("/{camisa_id}", status_code=204)
def apagar(
    camisa_id: int, 
    db: Session = Depends(get_db)
    ):
    service.apagar(db, camisa_id)
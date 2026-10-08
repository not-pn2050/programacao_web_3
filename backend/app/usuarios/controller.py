from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from .models import Usuario

from ..database import get_db
from ..segunraca import criar_token, get_current_user
from . import service
from .schemas import Token, UsuarioCriar, UsuarioPublico

router = APIRouter(
    prefix="/usuarios", 
    tags=["usuarios"],
)

@router.post("/", response_model=UsuarioPublico, status_code=201)
def cadastrar(dados: UsuarioCriar, db: Session = Depends(get_db)):
    return service.cadastrar(db, dados.model_dump())

@router.post("/login", response_model=Token)
def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):     
    usuario = service.autenticar(db, form.username, form.password)     
    return Token(access_token=criar_token(usuario.id))

@router.get("/eu", reponse_model=UsuarioPublico)
def eu(usuario: Usuario = Depends(get_current_user)):
    return usuario
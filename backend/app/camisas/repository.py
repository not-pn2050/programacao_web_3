from sqlalchemy.orm import Session

from .models import Camisa

def listar(db:Session, dono_id: int, time = str | None, temporada = str | None, cor = str | None, descricao = str | None):
    consulta = db.query(Camisa)
    if time:
        consulta = consulta.filter(Camisa.time.ilike(f"%{time}%"))
    return consulta.order_by(Camisa.time).all()

def buscar (db: Session, camisa_id: int):
    return db.query(Camisa).filter(Camisa.id == camisa_id).first()

def criar(db: Session, dados: dict):
    camisa = Camisa(**dados)
    db.add(camisa)
    db.commit()
    db.refresh(camisa)
    return camisa

def buscar_por_time(db: Session, time: str):
    print(time)
    return db.query(Camisa).filter(Camisa.time == time).first()

def atualizar(db: Session, camisa: Camisa, mudancas: dict):     
    for campo, valor in mudancas.items():         
        setattr(camisa, campo, valor)     
        db.commit()
        db.refresh(camisa)     
    return camisa

def apagar(db: Session, camisa: Camisa):     
    db.delete(camisa)     
    db.commit()
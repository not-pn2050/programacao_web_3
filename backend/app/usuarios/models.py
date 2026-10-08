from sqlalchemy import Column, Integer, String

from ..database import Base

class Usuario(Base):

    """A TABELA. Nao confunda com os schemas: aquilo atravessa a     
    fronteira da API, isto vira linha no banco.     
    """
    __tablename__ = 'usuarios'

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(100), nullable=False)
    email = Column(String(100), nullable=False, unique=True, index=True)
    senha_hash = Column(String(100), nullable=False)
    

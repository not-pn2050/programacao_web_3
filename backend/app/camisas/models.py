from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship


from ..database import Base

class Camisa(Base):

    """A TABELA. Nao confunda com os schemas: aquilo atravessa a     
    fronteira da API, isto vira linha no banco.     
    """
    __tablename__ = 'camisa'

    id = Column(Integer, primary_key=True, index=True)
    time = Column(String(20), nullable=False)
    temporada = Column(String(10), nullable=False)
    cor = Column(String(20), nullable=False)
    descricao = Column(String(500), nullable=False)
    pedido_id = Column(Integer, ForeignKey("CamisaPedido.id", name="fk_camisa_camisaPedido"))
    pedido = relationship("CamisaPedido", back_populates="camisas")
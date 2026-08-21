from pydantic import BaseModel, Field 

class CamisaCriar(BaseModel):
    time: str = Field(min_length=2)
    temporada: str = Field(min_length=2)
    cor: str = Field(min_length=1)
    descricao: str = Field(min_length=4)

class CamisaPublico(BaseModel):
    id: int     
    time: str
    temporada: str
    cor: str
    descricao: str

class CamisaAtualizar(BaseModel):
    id: int | None = None
    ime: str | None = None
    temporada: str | None = None
    cor: str | None = None
    descricao: str | None = None

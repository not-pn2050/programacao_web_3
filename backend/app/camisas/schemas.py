from pydantic import BaseModel, Field, field_validator, ConfigDict


def _valida_textos(time, temporada, cor):
    tamanho = len(time.strip())
    if tamanho < 2 or tamanho > 70:
        raise ValueError('o nome do time precisa ter pelo menos 2 caracteres')
    return time.strip()

class CamisaCriar(BaseModel):
    time: str
    temporada: str
    cor: str
    descricao: str

    @field_validator("time")
    @classmethod
    def nome_valido(cls, v):
        return _valida_textos(v)

class CamisaPublico(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int     
    time: str
    temporada: str
    cor: str
    descricao: str
    camisa_pedido_id: int | None


class CamisaAtualizar(BaseModel):
    id: int | None = None
    ime: str | None = None
    temporada: str | None = None
    cor: str | None = None
    descricao: str | None = None

    @field_validator("time")
    @classmethod
    def nome_valido(cls, v):
        return v if v is None else _valida_textos(v)

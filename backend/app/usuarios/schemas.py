from pydantic import BaseModel, ConfigDict, EmailStr, Field 


class UsuarioCriar(BaseModel):
    nome: str = Field(min_length=2)
    email: EmailStr 
    senha: str = Field(min_length=7)

class UsuarioPublico(BaseModel):
    model_config = ConfigDict(from_atributes=True)

    id: int
    nome: str
    email: EmailStr    

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

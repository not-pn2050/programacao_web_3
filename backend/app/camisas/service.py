from . import repository
from .erros import(
    NomeJaCadastrado,
    CamisaVendida,
    CamisaNaoEncontrada,
)

RN02_PROIBIDO = "disponivel"

def listar(db, usuario, time=None, temporada=None, cor=None, descricao=None):
    return repository.listar(db, usuario, time, temporada, cor, descricao)

def buscar(db, camisa_id):
    camisa = repository.buscar(db, camisa_id)
    if camisa is None:
        raise CamisaNaoEncontrada(f"Camisa {camisa_id} não esta no estoque")

def criar(db, dados):
    # RN01: a mesma camisa não entra duas vezes no estoque.
    if repository.buscar_por_time(db, dados['time']):
        raise NomeJaCadastrado(f'já existe um time cadastrado com esse nome {dados['time']}')
    return repository.criar(db,dados)

def atualizar(db, camisa_id, mudancas):     

    camisa = buscar(db, camisa_id)     
    novo_time = mudancas.get("titulo")     

    if novo_time and novo_time != camisa.time:         

        if repository.buscar_por_time(db, novo_time):
            raise CamisaNaoEncontrada(f"Ja existe um time chamado {novo_time}")     

        # if RN02_PROIBIDO in mudancas:
        #     raise CampoNaoEditavel("disponivel nao se edita pelo catalogo")     

        return repository.atualizar(db, camisa, mudancas)

def apagar(db, camisa_id):
    camisa = buscar(db, camisa_id)
    # RN03: camisa que esta com um leitor nao some do acervo.
    if not camisa.disponivel:
        raise CamisaVendida(f"Camisa {camisa_id} esta emprestado")
    repository.apagar(db, camisa)
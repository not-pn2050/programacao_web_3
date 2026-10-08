class ErroDeCamisa(Exception):
    """Qualquer recusa do estoque. Quem traduz para HTTP e o controller."""


class CamisaNaoEncontrada(ErroDeCamisa):     
    """Pediram uma camisa que nao esta no estoque.""" 


class NomeJaCadastrado(ErroDeCamisa):     
    """Ja existe uma camisa com esse titulo no estoque.""" 


class CampoNaoEditavel(ErroDeCamisa):     
    """Tentaram editar pelo catalogo um campo que nao e do catalogo.""" 


class CamisaVendida(ErroDeCamisa):     
    """Nao se apaga camisa que ja foi vendida."""
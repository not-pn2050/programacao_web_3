class ErroDeusuario(Exception):
    """Qualquer recusa ligada a contas e login. Quem traduz para HTTP e' o main.py"""

class EmailJaCadastrado(ErroDeusuario):
    """Ja' existe uma conta com esse e-mail."""

class CredenciaisInvalidas(ErroDeusuario):
    """E-mail ou senha errados, ou token invalido."""


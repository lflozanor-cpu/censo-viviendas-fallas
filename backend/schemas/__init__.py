"""Esquemas Pydantic."""
from .user import UserCreate, UserLogin, UserResponse, Token
from .vivienda import ViviendaCreate, ViviendaUpdate, ViviendaResponse
from .foto import FotoViviendaCreate, FotoViviendaResponse
from .falla import FallaGeologicaResponse

__all__ = [
    "UserCreate", "UserLogin", "UserResponse", "Token",
    "ViviendaCreate", "ViviendaUpdate", "ViviendaResponse",
    "FotoViviendaCreate", "FotoViviendaResponse",
    "FallaGeologicaResponse",
]

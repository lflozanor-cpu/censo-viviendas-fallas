"""Configuración del backend."""
import os
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Configuración de la aplicación."""
    
    # App
    APP_NAME: str = "Censo Viviendas Fallas Geológicas"
    DEBUG: bool = False
    
    # Database
    DATABASE_URL: str = "postgresql://postgres:1234@localhost:5432/censo_fallas"
    
    # JWT
    SECRET_KEY: str = "cambio-en-produccion-clave-secreta-jwt-muy-larga"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 horas
    
    # Upload
    UPLOAD_DIR: str = "uploads"
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10 MB
    
    # Cálculo IRV
    BUFFER_FALLA_METROS: float = 5.0
    
    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()

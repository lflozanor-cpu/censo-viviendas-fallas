"""Autenticación JWT."""
from datetime import datetime, timedelta
from uuid import UUID
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from config import get_settings
from database import get_db
from models import User

settings = get_settings()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def _truncate_for_bcrypt(password: str) -> str:
    """bcrypt solo admite hasta 72 bytes."""
    if not password:
        return ""
    b = password.encode("utf-8")
    if len(b) <= 72:
        return password
    return b[:72].decode("utf-8", errors="ignore")


def verify_password(plain: str, hashed: str) -> bool:
    # Siempre truncar a 72 bytes justo antes de bcrypt (nunca pasar más)
    p = (plain if isinstance(plain, str) else str(plain or "")) or ""
    p = p.encode("utf-8")[:72].decode("utf-8", errors="ignore")
    return pwd_context.verify(p, hashed)


def get_password_hash(password: str) -> str:
    p = (password if isinstance(password, str) else str(password or "")) or ""
    p = p.encode("utf-8")[:72].decode("utf-8", errors="ignore")
    return pwd_context.hash(p)


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
        )


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No autorizado",
    )
    payload = decode_token(token)
    user_id: str = payload.get("sub")
    if not user_id:
        raise credentials_exception
    user = db.query(User).filter(User.id == UUID(user_id)).first()
    if not user:
        raise credentials_exception
    if not user.is_active:
        raise credentials_exception
    return user

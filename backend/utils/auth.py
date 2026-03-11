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
    if len(password.encode("utf-8")) <= 72:
        return password
    return password.encode("utf-8")[:72].decode("utf-8", errors="ignore")


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(_truncate_for_bcrypt(plain), hashed)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(_truncate_for_bcrypt(password))


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

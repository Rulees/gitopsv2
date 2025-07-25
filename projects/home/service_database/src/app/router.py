from fastapi import APIRouter, Depends, Request
from typing import List
from sqlalchemy.orm import Session

from app.schemas import UserCreate, UserRead
from app.service import create_user, get_users
from database import get_db

router = APIRouter()

@router.get("/")
def read_root():
    return {"message": "Hello from FastAPI"}

@router.get("/health")
def health_check():
    return {"status": "ok"}

@router.get("/database")
def get_database():
    return {"database": "mysql"}

@router.get("/ip")
async def get_my_ip(request: Request):
    client_ip = request.client.host
    return {"Client IP": client_ip}

@router.get("/users", response_model=List[UserRead])
def read_users_endpoint(db: Session = Depends(get_db)):
    return get_users(db)

# POST
@router.post("/users", response_model=UserRead)
def create_user_endpoint(user: UserCreate, db: Session = Depends(get_db)):
    return create_user(db, user)
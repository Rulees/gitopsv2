from fastapi import FastAPI, Depends, Request
from sqlalchemy import create_engine, Column, Integer, String, MetaData
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from pydantic import BaseModel
from typing import List
import os

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI"}


@app.get("/health")
def health_check():
    return {"status": "ok"}


# Through GatewayAPI
@app.get("/database")
def get_database():
    return {"database": "mysql"}


@app.get("/ip")
async def get_my_ip(request: Request):
    client_ip = request.client.host
    return {"Client IP": client_ip}



##
# DataBase
##

# DATABASE_URL = "postgresql://LOMOKNM:NONO@c-c9q05cccurv0oq9kksis.rw.mdb.yandexcloud.net:6432/postgresql?sslmode=verify-full&sslrootcert=/root/.postgresql/root.crt"
DATABASE_URL = os.environ.get("DATABASE_URL")

metadata = MetaData(schema="this")
Base = declarative_base(metadata=metadata)

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)

class UserCreate(BaseModel):
    name: str

class UserRead(BaseModel):
    id: int
    name: str
    class Config:
        orm_mode = True

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.post("/users", response_model=UserRead)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = User(name=user.name)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.get("/users", response_model=List[UserRead])
def read_users(db: Session = Depends(get_db)):
    return db.query(User).all()
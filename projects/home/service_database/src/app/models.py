from sqlalchemy import Column, Integer, String, MetaData
from sqlalchemy.orm import declarative_base

metadata = MetaData(schema="this")
Base = declarative_base(metadata=metadata)

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
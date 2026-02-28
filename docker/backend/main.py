import os
from datetime import datetime
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker
from pydantic import BaseModel
from typing import List, Optional

# --- Database Setup (SQLite) ---
DB_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(DB_DIR, "archive.db")
DATABASE_URL = f"sqlite:///{DB_FILE}"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class MediaItem(Base):
    __tablename__ = "media_items"
    
    id = Column(Integer, primary_key=True, index=True)
    file_name = Column(String, index=True)
    file_type = Column(String) # 'image', 'document'
    file_ext = Column(String)  # '.png', '.pdf'
    access_url = Column(String) # e.g. /images/xxx.png
    file_size_kb = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow)

Base.metadata.create_all(bind=engine)


# --- Pydantic Models for Response ---
class MediaItemSchema(BaseModel):
    id: int
    file_name: str
    file_type: str
    access_url: str
    file_size_kb: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class PaginatedResponse(BaseModel):
    items: List[MediaItemSchema]
    total: int
    has_more: bool


# --- FastAPI App ---
app = FastAPI(title="Archive Vault API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Fine for a personal archive, customize for prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/api/v1/archives/images", response_model=PaginatedResponse)
def get_images(page: int = Query(1, ge=1), page_size: int = Query(24, ge=1, le=100)):
    db = SessionLocal()
    try:
        query = db.query(MediaItem).filter(MediaItem.file_type == 'image').order_by(MediaItem.created_at.desc())
        total = query.count()
        
        offset = (page - 1) * page_size
        items = query.offset(offset).limit(page_size).all()
        
        return {
            "items": items,
            "total": total,
            "has_more": offset + page_size < total
        }
    finally:
        db.close()

@app.get("/api/v1/archives/docs", response_model=PaginatedResponse)
def get_docs(page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100)):
    db = SessionLocal()
    try:
        query = db.query(MediaItem).filter(MediaItem.file_type == 'document').order_by(MediaItem.created_at.desc())
        total = query.count()
        
        offset = (page - 1) * page_size
        items = query.offset(offset).limit(page_size).all()
        
        return {
            "items": items,
            "total": total,
            "has_more": offset + page_size < total
        }
    finally:
        db.close()

@app.get("/api/v1/health")
def health_check():
    return {"status": "ok"}

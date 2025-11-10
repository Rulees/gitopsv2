from fastapi import FastAPI
from app.router import router
from admin_panel.router import router as admin_router



app = FastAPI()
app.include_router(router)
app.include_router(admin_router)
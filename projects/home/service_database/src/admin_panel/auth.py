import os
from fastapi import APIRouter, HTTPException, Request, Response, status, Form

router = APIRouter()
ADMIN_USERNAME = os.getenv("ADMIN_USERNAME")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD")

@router.post("/login")
async def login_admin(
    response: Response,
    username: str = Form(...),
    password: str = Form(...)
):
    if username != ADMIN_USERNAME or password != ADMIN_PASSWORD:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    # Можно поставить JWT, но пока делаем просто
    response.set_cookie(key="admin_token", value="ok", httponly=True, max_age=86400)
    return {"message": "✅ Login successful"}

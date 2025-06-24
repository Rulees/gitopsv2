from fastapi import FastAPI, Request
app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI"}


@app.get("/health")
def health_check():
    return {"status": "ok"}


@app.get("/name")
def get_name():
    return {"name": "John Doe"}


@app.get("/ip")
async def get_my_ip(request: Request):
    print("Received Headers:", request.headers)
    client_ip = request.client.host
    return {"Client IP": client_ip}
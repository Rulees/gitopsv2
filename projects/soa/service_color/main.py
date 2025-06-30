from fastapi import FastAPI, Request
app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI"}


@app.get("/health")
def health_check():
    return {"status": "ok"}


# Through GatewayAPI
@app.get("/color")
def get_color():
    return {"color": "Red"}


@app.get("/ip")
async def get_my_ip(request: Request):
    client_ip = request.client.host
    return {"Client IP": client_ip}

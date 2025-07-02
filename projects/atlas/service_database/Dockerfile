FROM python:3.11-slim

ARG DATABASE_URL
ENV DATABASE_URL=$DATABASE_URL


COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir -p /root/.postgresql

COPY . .
COPY /root/.postgresql/root.crt /root/.postgresql/root.crt

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--log-level", "info"]
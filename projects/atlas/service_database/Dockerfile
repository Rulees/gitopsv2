FROM python:3.11-slim

ARG DATABASE_URL
ENV DATABASE_URL=$DATABASE_URL

RUN mkdir -p /root/.postgresql

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
COPY root.crt /root/.postgresql/root.crt
ENV PYTHONPATH="/src"

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--log-level", "info"]

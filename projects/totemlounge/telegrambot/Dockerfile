FROM python:3.11-slim 

EXPOSE 80 443

ARG TOKEN
ARG ADMIN_CHAT_ID

ENV TOKEN=$TOKEN
ENV ADMIN_CHAT_ID=$ADMIN_CHAT_ID

RUN apt update && apt install -y --no-install-recommends \
    gcc libffi-dev libssl-dev openssl lnav nano curl jq \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --break-system-packages --no-cache-dir aiogram python-dotenv babel pytz nest_asyncio aiosqlite


COPY . .


CMD ["python", "main.py"]
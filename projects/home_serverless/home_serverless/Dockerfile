FROM nginx:1.27.4-alpine


RUN apk add --no-cache python3 py3-pip py3-setuptools py3-wheel gcc musl-dev libffi-dev openssl-dev openssl lnav nano curl jq \
    && pip3 install --break-system-packages --no-cache-dir yandexcloud PyJWT cryptography grpcio


COPY frontend/ /sites/starter/          
COPY nginx_conf/ /etc/nginx/
COPY entrypoint-serverless.sh /entrypoint-serverless.sh


RUN if ! getent group www-data; then addgroup -S www-data; fi && \
    if ! getent passwd www-data; then adduser -S www-data -G www-data; fi


RUN chmod +x /entrypoint-serverless.sh

ENTRYPOINT ["/entrypoint-serverless.sh"]

FROM nginx:1.27.4-alpine

RUN apk add --no-cache python3 openssl lnav nano curl jq

RUN if ! getent group www-data; then addgroup -S www-data; fi && \
    if ! getent passwd www-data; then adduser -S www-data -G www-data; fi

COPY nginx_serv/ /sites/starter/          
COPY nginx_conf/ /etc/nginx/
COPY entrypoint-serverless.sh /entrypoint-serverless.sh    


RUN chmod +x /entrypoint-serverless.sh

ENTRYPOINT ["/entrypoint-serverless.sh"]
#!/bin/sh
echo "---------Start entrypoint-serverless.sh"

# Проверяем, что переменные окружения заданы
if [ -z "$PORT" ]; then
  echo "----------ERROR: PORT env_var is not set!"
  exit 1
fi

echo "----------Use PORT: $PORT"


# Generate file *.conf with vars from .env
for file in /etc/nginx/conf.d/*.template /etc/nginx/conf.d/.*.template; do
    [ -e "$file" ] || continue
    envsubst '${PORT}' < "$file" > "${file%.template}"
    rm "$file"
done
echo "---------Conf files generated from .template"


# nginx &
# echo "---------Nginx launched"
exec nginx -g "daemon off;"
# cat /etc/nginx/sites-enabled/*
# tail -f /var/log/nginx/access.log /var/log/nginx/error.log

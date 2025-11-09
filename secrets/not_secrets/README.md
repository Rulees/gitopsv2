root.crt is a postgresql yandex cloud cert for connection

# wrong!

<!-- 1. DATABASE_URL output/secret is for fastapi, cause in Dockerfile we copy it from root.crt to /root/.postgresql/root.crt. so we use default path
2. Others outputs are for atlas to connect postgresql. So in terragrunt.hcl we use /secrets/not_secrets/root.crt -->

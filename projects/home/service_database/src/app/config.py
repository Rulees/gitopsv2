import os

# DATABASE_URL = "postgresql://LOMOKNM:NONO@c-c9q05cccurv0oq9kksis.rw.mdb.yandexcloud.net:6432/postgresql?sslmode=verify-full&sslrootcert=/root/.postgresql/root.crt"
DATABASE_URL = os.environ.get("DATABASE_URL")
# remove posgresql from remote state, if deleted manually
# posgresql
terragrunt state rm yandex_mdb_postgresql_cluster_v2.this     || true
terragrunt state rm yandex_mdb_postgresql_user.this     || true
terragrunt state rm yandex_mdb_postgresql_database.this     || true

# atlas
terragrunt state rm atlas_schema.main     || true
terragrunt state rm data.atlas_schema.this     || true


dev_url has to be similar to real one
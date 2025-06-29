# Default schema to aboid dropping
schema "public" {}



schema "this" {}

table "users" {
  schema = schema.this
  column "id" {
    null = false
    type = int
  }
  column "name" {
    null = false
    type = varchar(100)
  }
  primary_key {
    columns = [column.id]
  }
}
schema "myapp" {}

table "users" {
  schema = schema.myapp
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
##
# DEFAULT - to avoid errors
##

schema "public" {}


##
# SQL
##

# CREATE SCHEMA "this";
# CREATE TABLE "this"."users" (
#   "id" integer NOT NULL,
#   "name" character varying(100) NOT NULL,
#   PRIMARY KEY ("id")
# );

##
# HCL
##

schema "this" {}

table "users" {
  schema = schema.this
  column "id" {
    null = false
    type = int
    identity {
      generated = ALWAYS
      start     = 1
      increment = 1
    }
  }
  column "name" {
    null = false
    type = varchar(100)
  }
  primary_key {
    columns = [column.id]
  }
}
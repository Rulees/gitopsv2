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

table "estates" {
  schema = schema.public

  column "id" {
    null = false
    type = int
    identity {
      generated = ALWAYS
      start     = 1
      increment = 1
    }
  }

  column "title" {
    null = false
    type = varchar(150)
  }

  column "address" {
    null = false
    type = varchar(250)
  }

  column "price" {
    null = false
    type = float
  }

  column "estate_type" {
    null = false
    type = varchar(50)
  }

  column "image_url" {
    null = true
    type = text
  }

  column "created_at" {
    null    = false
    type    = timestamp
    default = "CURRENT_TIMESTAMP"
  }

  primary_key {
    columns = [column.id]
  }
}

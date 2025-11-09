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

table "items" {
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

  column "name" {
    null = false
    type = varchar(100)
  }

  column "category" {
    null = false
    type = varchar(50)
  }

  column "region" {
    null = false
    type = varchar(50)
  }

  column "status" {
    null = false
    type = varchar(20)
  }

  column "item_type" {
    null = false
    type = varchar(50)
  }

  column "image_url" {
    null = true
    type = text
  }

  primary_key {
    columns = [column.id]
  }
}

table "admin_users" {
  schema = schema.public # Assuming admin_users table is also in the 'public' schema

  column "id" {
    null = false
    type = int
    identity {
      generated = ALWAYS
      start     = 1
      increment = 1
    }
  }

  column "username" {
    null = false
    type = varchar(50)
  }

  column "password_hash" {
    null = false
    type = varchar(250)
  }

  primary_key {
    columns = [column.id]
  }
}
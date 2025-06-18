terraform {
  backend "s3" {
    region         = "ru-central1"
    bucket         = "project-dildakot--yc-backend--dmvlelmn"
    key            = "backend/terraform.tfstate"

    dynamodb_table = "project-dildakot--yc-backend--state-lock-table"

    endpoints = {
      s3       = "https://storage.yandexcloud.net",
      dynamodb = "https://docapi.serverless.yandexcloud.net/ru-central1/b1g6lfsqbtpq384k0vrj/etn4eoef8obmfvkvrhqs"
    }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}


module "backend" {
  source          = "../../modules/backend"
  backend_prefix  = "yc-backend"        # change to remote-backend
  project_prefix  = "project-dildakot"
}

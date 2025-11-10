provider "atlas" {
  dev_url                = var.dev_url
}

data "atlas_schema" "this" {
  src                    = var.src
}

resource "atlas_schema" "main" {
  url                    = var.url
  hcl                    = data.atlas_schema.this.hcl

  tx_mode                = var.transaction_mode
  exclude                = var.atlas_exclude
  
  # lint {
  #   review               = var.lint_review_mode
  #   review_timeout       = var.lint_review_time
  # }

  diff {
    concurrent_index {
      create             = var.concurrent_index.create
      drop               = var.concurrent_index.drop
    }
    skip {
      add_column         = var.skip.add_column
      add_foreign_key    = var.skip.add_foreign_key
      add_index          = var.skip.add_index
      add_schema         = var.skip.add_schema
      add_table          = var.skip.add_table

      drop_column        = var.skip.drop_column
      drop_foreign_key   = var.skip.drop_foreign_key
      drop_index         = var.skip.drop_index
      drop_schema        = var.skip.drop_schema
      drop_table         = var.skip.drop_table

      modify_column      = var.skip.modify_column
      modify_foreign_key = var.skip.modify_foreign_key
      modify_index       = var.skip.modify_index
      modify_schema      = var.skip.modify_schema
      modify_table       = var.skip.modify_table
    }
  }
}
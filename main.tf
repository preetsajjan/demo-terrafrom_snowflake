terraform {
  required_providers {
    snowflake = {
      source  = "chanzuckerberg/snowflake"
      version = "0.25.17"
    }
  }

  backend "remote" {
    organization = "trial_accunt"

    workspaces {
      name = "check_cicd_with_snowflake_demo"
    }
  }
}

provider "snowflake" {
  account   = var.snowflake_account
  user      = var.snowflake_user
  password  = var.snowflake_password
  region    = var.snowflake_region
}

variable "snowflake_account" {}
variable "snowflake_user" {}
variable "snowflake_password" {}
variable "snowflake_region" {}
variable "access_key" {}
variable "secret_key" {}

resource "snowflake_database" "demo_db" {
  name    = "DEMO_DB"
  comment = "Database for Snowflake Terraform demo"
}

resource "snowflake_schema" "demo_schema" {
  database = snowflake_database.demo_db.name
  name     = "DEMO_SCHEMA"
  comment  = "Schema for Snowflake Terraform demo"
}

resource "snowflake_table" "sensor" {
  database = snowflake_database.demo_db.name
  schema   = snowflake_schema.demo_schema.name
  name     = "WEATHER_JSON"

  column {
    name    = "var"
    type    = "VARIANT"
    comment = "Raw sensor data"
  }
}

resource "snowflake_file_format" "json" {
  name                 = "JSON_FORMAT"
  database             = snowflake_database.demo_db.name
  schema               = snowflake_schema.demo_schema.name
  format_type          = "JSON"
  strip_outer_array    = true
  compression          = "NONE"
  binary_format        = "HEX"
  date_format          = "AUTO"
  time_format          = "AUTO"
  timestamp_format     = "AUTO"
  skip_byte_order_mark = true
}

resource "snowflake_stage" "example_stage" {
  name        = "EXAMPLE_STAGE"
  url         = "s3://snowflake-nse-data/"
  database    = snowflake_database.demo_db.name
  schema      = snowflake_schema.demo_schema.name

  credentials = <<-EOT
    AWS_KEY_ID="${var.access_key}" AWS_SECRET_KEY="${var.secret_key}"
  EOT
}

resource "snowflake_view" "view" {
  database = snowflake_database.demo_db.name
  schema   = snowflake_schema.demo_schema.name
  name     = "NEW_VIEW"

  comment = "comment"

  statement = <<-SQL
    SELECT * FROM WEATHER_JSON;
  SQL

  or_replace = false
  is_secure  = false
}

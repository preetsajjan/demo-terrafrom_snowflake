terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
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
SNOWFLAKE_REGION = "singapore_asia_pacific"
SNOWFLAKE_ACCOUNT = "HR31688"
SNOWFLAKE_USER = "PREETIMITRA"
SNOWFLAKE_PASSWORD = "Preetimitra@2024"
}

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
  provider = snowflake
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
  provider             = snowflake
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
  database    = "DEMO_DB"
  schema      = "DEMO_SCHEMA"
  credentials =  "AWS_KEY_ID='${var.access_key}' AWS_SECRET_KEY='${var.secret_key}'"
}
resource "snowflake_view" "view" {
  database = "DEMO_DB"
  schema   = "DEMO_SCHEMA"
  name     = "NEW_VIEW"

  comment = "comment"

  statement  = <<-SQL
    select * from WEATHER_JSON;
SQL
  or_replace = false
  is_secure  = false
}

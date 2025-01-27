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
  account  = var.SNOWFLAKE_ACCOUNT
  username = var.SNOWFLAKE_USER
  password = var.SNOWFLAKE_PASSWORD
  region   = var.SNOWFLAKE_REGION
}

variable "SNOWFLAKE_ACCOUNT" {}
variable "SNOWFLAKE_USER" {}
variable "SNOWFLAKE_PASSWORD" {}
variable "SNOWFLAKE_REGION" {}

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
  url         = "@~/example_stage"
  database    = snowflake_database.demo_db.name
  schema      = snowflake_schema.demo_schema.name
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

# Insert dummy data into WEATHER_JSON table
resource "snowflake_sql" "insert_data" {
  database = snowflake_database.demo_db.name
  schema   = snowflake_schema.demo_schema.name
  statement = <<SQL
    INSERT INTO WEATHER_JSON (var)
    VALUES
      (PARSE_JSON('{"sensor_id": 1, "location": "Singapore", "temperature": 30.5, "humidity": 70, "timestamp": "2025-01-27T12:00:00Z"}')),
      (PARSE_JSON('{"sensor_id": 2, "location": "New York", "temperature": -2.3, "humidity": 55, "timestamp": "2025-01-27T12:10:00Z"}')),
      (PARSE_JSON('{"sensor_id": 3, "location": "Tokyo", "temperature": 16.4, "humidity": 80, "timestamp": "2025-01-27T12:20:00Z"}')),
      (PARSE_JSON('{"sensor_id": 4, "location": "London", "temperature": 10.2, "humidity": 60, "timestamp": "2025-01-27T12:30:00Z"}'));
SQL
}

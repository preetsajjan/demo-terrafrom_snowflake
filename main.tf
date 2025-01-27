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

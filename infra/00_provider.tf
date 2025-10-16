terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.91.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.16.0"
    }
  }
}

provider "databricks" {
  host  = var.databricks_host
  token = var.databricks_token
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

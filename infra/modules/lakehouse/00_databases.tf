resource "aws_glue_catalog_database" "bronze_db" {
  name         = var.bronze_db_name
  location_uri = var.bronze_db_s3_location
}

resource "aws_glue_catalog_database" "silver_db" {
  name         = var.silver_db_name
  location_uri = var.silver_db_s3_location
}

resource "aws_glue_catalog_database" "gold_db" {
  name         = var.gold_db_name
  location_uri = var.gold_db_s3_location
}

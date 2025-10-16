module "lakehouse" {
  source = "./modules/lakehouse"

  bronze_db_name        = "bronze_db"
  bronze_db_s3_location = "s3://${var.bucket_bronze_layer}"

  silver_db_name        = "silver_db"
  silver_db_s3_location = "s3://${var.bucket_silver_layer}"

  gold_db_name        = "gold_db"
  gold_db_s3_location = "s3://${var.bucket_gold_layer}"
}

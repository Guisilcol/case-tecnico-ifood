
resource "databricks_schema" "bronze_db" {
  catalog_name = "workspace"
  name         = "bronze_db"
  storage_root = "s3://${var.bucket_bronze_layer}"
  comment      = "Schema bronze para dados brutos"
}

resource "databricks_schema" "silver_db" {
  catalog_name = "workspace"
  name         = "silver_db"
  storage_root = "s3://${var.bucket_silver_layer}"
  comment      = "Schema silver para dados refinados"
}

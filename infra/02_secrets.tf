

resource "databricks_secret_scope" "s3_access_keys" {
  name = "s3-access-keys"
}

resource "databricks_secret" "aws_access_key_id" {
  key          = "AWS_ACCESS_KEY_ID"
  string_value = var.aws_access_key_id
  scope        = databricks_secret_scope.s3_access_keys.name
}

resource "databricks_secret" "aws_secret_access_key" {
  key          = "AWS_SECRET_ACCESS_KEY"
  string_value = var.aws_secret_access_key
  scope        = databricks_secret_scope.s3_access_keys.name
}
